require 'mixed_models'

describe LMM do
  ["#from_formula", "#from_daru"].each do |constructor_method|
    describe constructor_method do
      context "with nested random effects" do
        
        let(:df) { Daru::DataFrame.from_csv("spec/data/nested_effects_data.csv") }

        subject(:model_fit) do
          case constructor_method
          when "#from_formula"
            LMM.from_formula(formula: "y ~ 1 + (1 | a:b)", data: df)
          when "#from_daru"
            LMM.from_daru(response: :y, fixed_effects: [:intercept], 
                          random_effects: [[:intercept]], grouping: [[:a, :b]], data: df)
          end
        end

        # Results from R:
        #  > mod <- lmer(y~1+(1|a:b), df)
        #  > summary(mod)
        #  Linear mixed model fit by REML ['lmerMod']
        #  Formula: y ~ 1 + (1 | a:b)
        #     Data: df
        #
        #  REML criterion at convergence: 43.5
        #
        #  Scaled residuals: 
        #       Min       1Q   Median       3Q      Max 
        #  -3.12552 -0.58851  0.00321  0.54827  2.93780 
        #
        #  Random effects:
        #   Groups   Name        Variance Std.Dev.
        #   a:b      (Intercept) 0.9367   0.9679  
        #   Residual             0.0659   0.2567  
        #  Number of obs: 100, groups:  a:b, 6
        #
        #  Fixed effects:
        #              Estimate Std. Error t value
        #  (Intercept)    1.045      0.396   2.639
        #  > ranef(mod)
        #  $`a:b`
        #        (Intercept)
        #  a1:b1  -0.3767391
        #  a1:b2   1.0009895
        #  a2:b1   0.2707781
        #  a2:b2  -1.7495081
        #  a3:b1   0.3284493
        #  a3:b2   0.5260302

        it "computes the REML criterion correctly" do
          expect(model_fit.deviance).to be_within(1e-1).of(43.5)
        end

        it "computes the fixed effect estimates correctly" do
          expect(model_fit.fix_ef[:intercept]).to be_within(1e-3).of(1.045)
        end

        it "computes the random effects correctly" do
          results_from_R = [-0.3767391, 1.0009895, 0.2707781, -1.7495081, 0.3284493, 0.5260302]
          results = model_fit.ran_ef.values
          results.zip(results_from_R).each do |pair|
            expect(pair[0]).to be_within(1e-4).of(pair[1])
          end
        end

        it "names the fixed effects correctly" do
          expect(model_fit.fix_ef_names).to eq([:intercept])
        end

        it "names the random effects correctly" do
          names = [:intercept_a1_and_b1,:intercept_a1_and_b2,
                   :intercept_a2_and_b1,:intercept_a2_and_b2,
                   :intercept_a3_and_b1,:intercept_a3_and_b2]
          expect(model_fit.ran_ef_names).to eq(names)
        end
      end

      context "with crossed and nested random effects" do
        
        let(:df) { Daru::DataFrame.from_csv("spec/data/crossed_and_nested_effects_data.csv") }

        subject(:model_fit) do
          case constructor_method
          when "#from_formula"
            LMM.from_formula(formula: "y ~ 1 + (1|a) + (1 | a:b)", data: df)
          when "#from_daru"
            LMM.from_daru(response: :y, fixed_effects: [:intercept], 
                          random_effects: [[:intercept], [:intercept]], grouping: [:a, [:a, :b]], data: df)
          end
        end

        # Results from R:
        #  > mod = lmer(y~1+(1|a)+(1|a:b), data=df)
        #  > summary(mod)
        #  Linear mixed model fit by REML ['lmerMod']
        #  Formula: y ~ 1 + (1 | a) + (1 | a:b)
        #     Data: df
        #
        #  REML criterion at convergence: 47.4
        #
        #  Scaled residuals: 
        #       Min       1Q   Median       3Q      Max 
        #  -3.12034 -0.57924 -0.00378  0.54810  2.94847 
        #
        #  Random effects:
        #   Groups   Name        Variance Std.Dev.
        #   a:b      (Intercept) 1.0090   1.0045  
        #   a        (Intercept) 2.5398   1.5937  
        #   Residual             0.0659   0.2567  
        #  Number of obs: 100, groups:  a:b, 6; a, 3
        #
        #  Fixed effects:
        #              Estimate Std. Error t value
        #  (Intercept)   0.9528     1.0077   0.946
        #  > ranef(mod)
        #  $`a:b`
        #        (Intercept)
        #  a1:b1  -0.7607407
        #  a1:b2   0.6186263
        #  a2:b1   0.7639397
        #  a2:b2  -1.2577348
        #  a3:b1   0.2192124
        #  a3:b2   0.4166969
        #
        #  $a
        #     (Intercept)
        #  a1  -0.3577111
        #  a2  -1.2429141
        #  a3   1.6006252

        it "computes the REML criterion correctly" do
          expect(model_fit.deviance).to be_within(1e-1).of(47.4)
        end

        it "computes the fixed effect estimates correctly" do
          expect(model_fit.fix_ef[:intercept]).to be_within(1e-2).of(0.9528)
        end

        it "computes the random effects correctly" do
          results_from_R = [-0.3577111, -1.2429141, 1.6006252, -0.7607407, 0.6186263, 
                            0.7639397, -1.2577348, 0.2192124, 0.4166969]
          results = model_fit.ran_ef.values
          results.zip(results_from_R).each do |pair|
            expect(pair[0]).to be_within(1e-3).of(pair[1])
          end
        end

        it "names the fixed effects correctly" do
          expect(model_fit.fix_ef_names).to eq([:intercept])
        end

        it "names the random effects correctly" do
          names = [:intercept_a1, :intercept_a2, :intercept_a3,
                   :intercept_a1_and_b1,:intercept_a1_and_b2,
                   :intercept_a2_and_b1,:intercept_a2_and_b2,
                   :intercept_a3_and_b1,:intercept_a3_and_b2]
          expect(model_fit.ran_ef_names).to eq(names)
        end
      end
    end
  end
end

