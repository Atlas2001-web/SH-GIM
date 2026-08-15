# SH-GIM

> **Public-release note:** The normal-equation assembly and solver component
> is proprietary and is intentionally not included in this repository. The
> public code therefore cannot run the final SH inversion end-to-end.

用于基于 GNSS 观测数据构建全球电离层图（GIM）的 MATLAB 代码。项目实现了观测数据预处理、卫星轨道插值、P4 观测值计算、球谐模型求解与 VTEC 产品生成等流程。

## 包含内容

- `main_unpackdata.m`：主处理入口。
- `Step1.m`、`Step2.m`、`Step3.m`、`GET_NE.m`：主要处理步骤。
- `functions/`、`sub_functions/`：计算、下载、读写与绘图辅助函数。
- `tests/`：轻量级 MATLAB 检查脚本。

## 环境要求

- MATLAB（并行处理步骤需要 Parallel Computing Toolbox）。
- 自行准备合规的 GNSS 观测、SP3 轨道和其他输入数据。
- 如需解压或地图绘制功能，请自行安装并配置相应的外部工具（例如 GFZRNX、M_Map），并遵守它们各自的许可证。

## 快速开始

1. 将项目根目录设为 MATLAB 当前工作目录。
2. 在 `main_unpackdata.m` 中设置数据目录与处理时间范围。脚本中的 `packFilePath`、`stations_txt` 和 `unpack_outdir` 是本地示例路径，使用前必须改为自己的路径。
3. 根据需要调用：

   ```matlab
   main_unpackdata
   ```

   默认会依次执行主要处理步骤；也可以通过函数参数单独控制初始化和各处理步骤。

## 数据与结果

本仓库刻意不包含原始 GNSS 数据、中间 `.mat` 文件、SP3/RINEX 文件、结果图或其他生成物。请从原始数据提供方获取数据，并遵守其使用条款。

## 许可证

本项目的原创代码以 [MIT License](LICENSE) 发布。仓库不包含第三方二进制工具或第三方工具箱；它们应从各自的官方来源单独获取。
