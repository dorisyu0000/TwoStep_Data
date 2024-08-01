using CSV
using DataFrames
using RCall

# Load the CSV files into DataFrames
# Load the CSV files into DataFrames
data1 = CSV.read("data/human/v3.7/trial1.csv", DataFrame)
data2 = CSV.read("data/human/v3.7/trial2.csv", DataFrame)

# Add a column to each DataFrame to indicate the dataset source
data1[:, :dataset] = fill("Dataset1", nrow(data1))
data2[:, :dataset] = fill("Dataset2", nrow(data2))

# Combine the data into one DataFrame
combined_data = vcat(data1, data2)
@rput combined_data 
R"library(lmerTest)"

# Fit the mixed-effects model and print the summary

R"model_combined <- lmer(RT_second_visit ~  dataset + (1|wid), data = combined_data)"
R"model_combined <- lmer(RT_first_visit ~  dataset + (1|wid), data = combined_data)"
R"model_combined <- lmer(RT ~  dataset + (1|wid), data = combined_data)"
R"summary(model_combined)"
R"plot(residuals(model_combined) ~ fitted(model_combined))"
R"qqnorm(residuals(model_combined))"
R"qqline(residuals(model_combined))"



function output_results(model_summary, prefix, dir="data_text")
    # Create the directory if it does not exist
    if !isdir(dir)
        mkpath(dir)
    end

    # Extract the necessary statistics and write them to separate files
    coeffs = model_summary[:coefficients]
    open("$(dir)/$(prefix)_b.txt", "w") do f
        write(f, string(round(coeffs[2, 1], digits=5)))  # b
    end
    open("$(dir)/$(prefix)_se.txt", "w") do f
        write(f, string(round(coeffs[2, 2], digits=5)))  # SE
    end
    open("$(dir)/$(prefix)_t.txt", "w") do f
        write(f, string(round(coeffs[2, 4], digits=2)))  # t-value
    end
    open("$(dir)/$(prefix)_df.txt", "w") do f
        write(f, string(round(coeffs[2, 3], digits=1)))  # degrees of freedom
    end
    open("$(dir)/$(prefix)_p.txt", "w") do f
        p_val = coeffs[2, 5] < 0.001 ? "< .001" : string(round(coeffs[2, 5], digits=4))
        write(f, p_val)  # p-value
    end
end

# Load data
data1 = CSV.read("data/human/v3.7/trial1.csv", DataFrame)
data2 = CSV.read("data/human/v3.7/trial2.csv", DataFrame)

# Run model for Data 1
@rput data1
R"library(lmerTest)"
R"model1 <- lmer(accuracy ~ difficulty + (1|wid), data = data1)"
model1_summary = R"summary(model1)"
output_results(model1_summary, "configA")

# Run model for Data 2
@rput data2
R"model2 <- lmer(accuracy ~ difficulty + (1|wid), data = data2)"
model2_summary = R"summary(model2)"
output_results(model2_summary, "configB")



function output_results(model_summary, prefix, dir="data_text", rt_type="rt_first")
    # Ensure the directory exists
    if !isdir(dir)
        mkpath(dir)
    end

    # Extract and write t, df, and p values to separate files
    coeffs = model_summary[:coefficients]
    t_file = joinpath(dir, prefix * "_" * rt_type * "_t.txt")
    df_file = joinpath(dir, prefix * "_" * rt_type * "_df.txt")
    p_file = joinpath(dir, prefix * "_" * rt_type * "_p.txt")

    open(t_file, "w") do f
        write(f, string(round(coeffs[2, 4], digits=2)))  # t-value
    end
    open(df_file, "w") do f
        write(f, string(round(coeffs[2, 3], digits=1)))  # degrees of freedom
    end
    open(p_file, "w") do f
        p_val = coeffs[2, 5] < 0.00001 ? "< .001" : string(round(coeffs[2, 5], digits=6))
        write(f, p_val)  # p-value
    end
end

# Models and output for first visit
@rput data1
R"model1_first <- lmer(RT_first_visit ~ difficulty + (1|wid), data = data1)"
first1_summary = R"summary(model1_first)"
output_results(first1_summary, "configA", "data_text", "rt_first")

@rput data2
R"model2_first <- lmer(RT_first_visit ~ difficulty + (1|wid), data = data2)"
first2_summary = R"summary(model2_first)"
output_results(first2_summary, "configB", "data_text", "rt_first")

# Models and output for second visit
R"model1_second <- lmer(RT_second_visit ~ difficulty_2 + (1|wid), data = data1)"
second1_summary = R"summary(model1_second)"
output_results(second1_summary, "configA", "data_text", "rt_second")

@rput data2
R"model2_second <- lmer(RT_second_visit ~ difficulty_2 + (1|wid), data = data2)"
second2_summary = R"summary(model2_second)"
output_results(second2_summary, "configB", "data_text", "rt_second")


function output_model_results(model_summary, prefix, rt_type, dir="data_text")
    # Ensure the directory exists
    if !isdir(dir)
        mkpath(dir)
    end
    
    # Extract coefficients specifically targeting the 'dataset' effect
    dataset_effect = filter(row -> row[:term] == "dataset", model_summary[:coefficients])
    
    # Creating filenames using proper concatenation
    t_file = joinpath(dir, "$(prefix)_${rt_value}_tree_t.txt")
    df_file = joinpath(dir, "$(prefix)_${rt_value}_tree_df.txt")
    p_file = joinpath(dir, "$(prefix)_${rt_value}_tree_p.txt")

    # Open files and write the results
    open(t_file, "w") do f
        write(f, string(round(dataset_effect[:t][1], digits=2)))  # Ensure accessing the first row correctly for t-value
    end
    open(df_mode_df_file, "w") do f
        write(f, string(round(dataset_effect[:df][1], digits=1)))  # Ensure accessing the first row correctly for degrees of freedom
    end
    open(p_file, "w") do f
        p_val = dataset_effect[:p][1] < 0.00001 ? "< .001" : string(round(dataset_effect[:p][1], digits=6))
        write(f, p_val)  # Ensure accessing the first row correctly for p-value
    end
end

# Plot for RT by difficulty


