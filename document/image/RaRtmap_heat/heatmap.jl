using Plots
using YAML
using Statistics
using Glob

const NUM_ATOMS = 1250

function process_files(yaml_dir, lammpstrj_dir)
    # Find all YAML files in the YAML directory
    yaml_files = glob("*.yaml", yaml_dir)

    for yaml_file in yaml_files
        # Load YAML file
        data = YAML.load_file(yaml_file)

        # Extract necessary data from YAML
        parameter_list = ["time", "Yg"]
        extracted_data = Dict{String, Any}()
        for parameter in parameter_list
            extracted_data[parameter] = [entry[parameter] for entry in data]
        end

        time_values = extracted_data["time"]
        Yg_values = extracted_data["Yg"] ./ 80

        # Find corresponding lammpstrj file
        filename = basename(yaml_file)
        lammpstrj_file = joinpath(lammpstrj_dir, replace(filename, r"yaml$" => "lammpstrj"))

        # Read lammpstrj file
        data = read_atoms_data(lammpstrj_file)
        y_std_deviations = calculate_y_std_deviation(data["atoms_data"], NUM_ATOMS)

        # Plot and save image
        # plt = plot(Yg_values, y_std_deviations, label="", st=scatter, mc=:red, ms=5, xlims=(0.2, 0.8))
        plt = histogram2d(Yg_values[201:1001],y_std_deviations[201:1001],bins=(50,50),color=:Reds,norm=true)
        xlims!(0.2,0.8)
        ylims!(0.1,0.4)
        title!("Heatmap: (StD of y)/Ly vs. Yg/Ly")
        xlabel!("Yg/Ly")
        ylabel!("(StD of y)/Ly")
        savefig(plt, replace(filename, r".yaml$" => ".png"))
    end
end

function read_atoms_data(lammpstrj_file)
    data = Dict{String, Any}()
    atoms_data = Float64[]
    time_data = Float64[]

    open(lammpstrj_file, "r") do file
        timestep_section = false
        atoms_section = false
        
        for line in eachline(file)
            if occursin("ITEM: TIMESTEP", line)
                step = parse(Float64, readline(file))
                time = step * 0.005
                push!(time_data, time)
            elseif occursin("ITEM: ATOMS", line)
                atoms_section = true
            elseif atoms_section && !occursin("ITEM:", line)
                parts = split(line)
                push!(atoms_data, parse(Float64, parts[3])/80) # yのデータが記述される列を指定.
            else
                atoms_section = false
            end
        end
    end
    
    data["time_data"] = time_data
    data["atoms_data"] = atoms_data
    return data
end

function calculate_y_std_deviation(atoms_data, num_atoms)
    time_steps = length(atoms_data) ÷ num_atoms
    standard_deviations = Float64[]
    Yg_values = Float64[]
    for i in 1:time_steps
        start_index = (i - 1) * num_atoms + 1
        end_index = i * num_atoms
        positions = atoms_data[start_index:end_index]
        push!(Yg_values, mean(positions))
        push!(standard_deviations, std(positions,corrected=false))
    end
    
    return standard_deviations
end

# Specify directories containing YAML and lammpstrj files
yaml_directory = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir"
lammpstrj_directory = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/lammpstrjdir"

# Process files
process_files(yaml_directory, lammpstrj_directory)
