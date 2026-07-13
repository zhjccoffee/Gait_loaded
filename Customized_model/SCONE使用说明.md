# 在 SCONE 中打开并优化 loaded gait 模型

## 使用文件

- `Gait_loaded_optimization.scone`：在 SCONE Studio 中打开的优化入口。
- `2D_gait_15Rloaded_SCONE.osim`：供 SCONE 使用的兼容模型。
- `2D_gait_15Rloaded_OpenSim.osim`：供 OpenSim GUI 查看、默认脚底位于地面的模型。
- `2D_gait_15Rloaded.osim`：原始模型，未修改。
- `InitState_loaded.zml`：初始步态姿态、速度和肌肉激活。
- `make_scone_model.ps1`：原始模型更新后，用来重新生成 SCONE 兼容模型。

## 打开与显示

1. 启动 SCONE Studio。
2. 选择 **File → Open**，打开 `Gait_loaded_optimization.scone`。
3. 创建/评估场景后，模型会显示在右侧 3D 视图中。

本配置依赖 SCONE 自带的 `Documents/SCONE/Examples` 控制器、测度和预训练参数；当前电脑已安装这些文件。

## 开始优化

在 `Gait_loaded_optimization.scone` 打开的情况下启动优化。配置使用 H0918 两状态反射步态控制器作为初值，目标包含行走速度、代谢/肌肉 effort、膝关节限制和地面反力。

`initial_load = 0` 是有意设置：这个 OpenSim 4 模型的骨盆关节名是 `groundPelvis`，而 SCONE 的自动初始加载功能固定查找旧示例中的 `ground_pelvis` 路径。骨盆高度和肌肉激活已由 `InitState_loaded.zml` 提供。

## 为什么需要兼容模型

原始文件把肌肉和接触力放在顶层 `<components>` 中，SCONE 的 OpenSim 4 适配器因此找不到可控肌肉。原始模型还为每只脚使用两个独立的 `SmoothSphereHalfSpaceForce`，而步态状态控制器需要一个可识别的脚接触力。

兼容模型做两项机械转换：

1. 将执行器和力移入 OpenSim `ForceSet`，使 18 个肌肉可由 SCONE 控制。
2. 将每只脚的 heel/front 接触合并成 `HuntCrossleyForce`：`foot_r` 和 `foot_l`，保持原始刚度、耗散和摩擦参数。

如果修改了原始 `.osim`，可在 PowerShell 中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\make_scone_model.ps1
```
