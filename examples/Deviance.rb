require 'mixed_models'

# Generate the fixed effects design matrix
x_array = Array.new(50) { 1 }
x_array.each_index { |i| x_array[i]=(i+1)/2 if (i+1)%2==0 } 
x = NMatrix.new([25,2], x_array, dtype: :float64)

# Fixed effects coefficient vector
beta = NMatrix.new([2,1], [2,3], dtype: :float64)

# Generate the mixed effects model matrix
# (Assume a group structure with five groups of equal size)
grp_mat = NMatrix.zeros([25,5], dtype: :float64)
[0,5,10,15,20].each { |i| grp_mat[i...(i+5), i/5] = 1.0 }
# (Create matrix for random intercept and slope)
z = grp_mat.khatri_rao_rows x

# Generate the random effects vector 
# Values generated by R from the multivariate distribution with mean 0
# and covariance matrix [ [1, 0.5], [0.5, 1] ]
b_array = [ -1.34291864, 0.37214635,-0.42979766, 0.03111855, 1.98241161, 
            0.71735038, 0.40448848,-0.28236437, 0.33479745,-0.11086452 ]
b = NMatrix.new([10,1], b_array, dtype: :float64)

# Generate the random residuals vector
# Values generated from the standard Normal distribution
epsilon_array = [ 1.7049032,-0.7120386,-0.2779849,-0.1196490,-0.1239606, 0.2681838,
                  0.7268415, 0.2331354, 0.3391139,-0.5519147, 0.3477014, 1.4845918,
                  0.1883255, 2.4432598,-1.1534395,-0.8046717, 0.4560691, 0.4203326,
                  0.5775845, 0.4463561, 0.9172555,-0.1070615, 0.9883354,-1.0722388,
                 -0.7580153 ]
epsilon = NMatrix.new([25,1], epsilon_array, dtype: :float64)
 
# Generate the response vector
y = (x.dot beta) + (z.dot b) + epsilon

# Set up the random effects covariance parameters
lambdat = NMatrix.identity(10, dtype: :float64)

# Set up an LMMData object
model_data = LMMData.new(x: x, y: y, zt: z.transpose, lambdat: lambdat) do |th| 
  diag_blocks = Array.new(5) { NMatrix.new([2,2], [th[0],th[1],0,th[2]], dtype: :float64) }
  NMatrix.block_diagonal(*diag_blocks, dtype: :float64) 
end

# Set up the deviance function
dev_fun = MixedModels::mk_lmm_dev_fun(model_data, false)
reml_fun = MixedModels::mk_lmm_dev_fun(model_data, true)

# Evaluate
puts "Compare to values obtained by plsJSS from lme4pureR package in R"
puts "Deviance function"
puts "Theta: [1,1,1]   \t MixedModels: ~#{dev_fun.call([1,1,1]).round(5)}   \t lme4pureR: ~97.24135 \t Difference: #{(dev_fun.call([1,1,1]) - 97.2413512375).abs}"
puts "Theta: [1,2,3]   \t MixedModels: ~#{dev_fun.call([1,2,3]).round(5)}   \t lme4pureR: ~106.0938 \t Difference: #{(dev_fun.call([1,2,3]) - 106.09376025).abs}"
puts "Theta: [1,0.5,1] \t MixedModels: ~#{dev_fun.call([1,0.5,1]).round(5)} \t\t lme4pureR: ~95.3270 \t Difference: #{(dev_fun.call([1,0.5,1]) - 95.3270000775).abs}"
puts "Theta: [2,2,2]   \t MixedModels: ~#{dev_fun.call([2,2,2]).round(5)}   \t lme4pureR: ~104.0388 \t Difference: #{(dev_fun.call([2,2,2]) - 104.038774653).abs}"
puts "REML criterion"
puts "Theta: [1,1,1]   \t MixedModels: ~#{reml_fun.call([1,1,1]).round(5)}  \t lme4pureR: ~94.90857 \t Difference: #{(reml_fun.call([1,1,1]) - 94.9085716471).abs}"
puts "Theta: [1,2,3]   \t MixedModels: ~#{reml_fun.call([1,2,3]).round(5)}  \t lme4pureR: ~101.9385 \t Difference: #{(reml_fun.call([1,2,3]) - 101.938487224).abs}"
puts "Theta: [1,0.5,1] \t MixedModels: ~#{reml_fun.call([1,0.5,1]).round(5)} \t lme4pureR: ~93.3570   \t Difference: #{(reml_fun.call([1,0.5,1]) - 93.357039525).abs}"
puts "Theta: [2,2,2]   \t MixedModels: ~#{reml_fun.call([2,2,2]).round(5)} \t lme4pureR: ~99.9806 \t Difference: #{(reml_fun.call([2,2,2]) - 99.980568418).abs}"
