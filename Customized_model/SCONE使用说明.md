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

本配置面向服务器目录 `Documents/Projects/Gait_loaded/Customized_model`，依赖 `Documents/SCONE/Examples` 中的控制器和预训练参数。

## 开始优化

在 `Gait_loaded_optimization.scone` 打开的情况下启动优化。当前配置是第一阶段稳定行走优化：仿真时长 5 秒、目标速度 0.5 m/s，并加入腰部姿态反馈来控制负重躯干。SCONE 将 OpenSim 的 `lumbarAct` 按其坐标名暴露为执行器 `lumbar`，所以控制器中使用 `target = lumbar`。

第一阶段得到能够稳定走满 5 秒的结果后，再以最佳 `.par` 为初值，将仿真时长逐步提高到 10 秒和 20 秒，并恢复 effort、膝关节限制和地面反力测度。

SCONE 兼容模型将根关节规范为 `ground_pelvis`，使 H0918 预训练参数中的状态路径能够正确匹配，并允许 `initial_load = 1` 在仿真开始前根据重力和接触载荷调整初始状态。OpenSim 显示版仍保留原始关节名称。

## 为什么需要兼容模型

原始文件把肌肉和接触力放在顶层 `<components>` 中，SCONE 的 OpenSim 4 适配器因此找不到可控肌肉。原始模型还为每只脚使用两个独立的 `SmoothSphereHalfSpaceForce`，而步态状态控制器需要一个可识别的脚接触力。

兼容模型做两项机械转换：

1. 将执行器和力移入 OpenSim `ForceSet`，使 18 个肌肉可由 SCONE 控制。
2. 将每只脚的 heel/front 接触合并成 `HuntCrossleyForce`：`foot_r` 和 `foot_l`，保持原始刚度、耗散和摩擦参数。

如果修改了原始 `.osim`，可在 PowerShell 中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\make_scone_model.ps1
```
