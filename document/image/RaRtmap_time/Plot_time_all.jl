# あるyamlディレクトリのファイル全ての時系列グラフをそれぞれプロットして, 画像を生成.

using Plots
using YAML
using FilePaths

function plot_data(data)
    time = [entry["time"] for entry in data]
    Yg_value = [entry["Yg"] for entry in data]

    plot(time, Yg_value / 80, label="Yg", legend=:topleft)
    xlabel!("time")
    ylabel!("Yg/Ly")
    title!("Yg vs. time")
    ylims!(0.2, 0.8)
end

# 対象ディレクトリ内のYAMLファイルを取得
yaml_directory = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_ness/240129outputdir/yamldir"
yaml_files = filter(x -> occursin(".yaml", x), readdir(yaml_directory))

for yaml_file in yaml_files
    yaml_file_path = joinpath(yaml_directory, yaml_file)
    data = YAML.load_file(yaml_file_path)
    plot_data(data)

    # 画像のファイル名を生成
    file_name_without_ext = splitext(yaml_file)[1]
    output_file_name = file_name_without_ext * ".png"

    # 画像の保存
    savefig(output_file_name)

    # プロットをクリア
    plot!()
end
