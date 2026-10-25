# LiquidGlass · 鸿蒙液态玻璃底部导航栏

用 ArkUI 手写还原 iOS 27 App Store 的**悬浮液态玻璃 TabBar**：实时背景模糊、顶部白霜、镜面描边、选中玻璃透镜、膨胀回弹与青琥珀色散。

> 目标设备：HarmonyOS 模拟器（API 20，1280 × 2832）
> 构建配置：`compatibleSdkVersion 4.0.0(10)`，`targetSdkVersion 26.0.0`
> 实际能力下限为 **API 12**（`backgroundEffect` 11、`clip` 12、`getUIContext` 11）

![效果](docs/screenshots/bar-over-color.jpg)

## 效果拆解

| 层 | 做法 |
| --- | --- |
| 背景模糊 | `backgroundEffect({ radius: 26, saturation: 2.0, brightness: 1.06 })` |
| 顶部白霜 → 中部清澈 → 底部反光 | 纵向白色 `linearGradient` |
| 镜面描边 / 高光 / 色散 | `GlassRim` Canvas 绘制 |
| 选中透镜 | 独立玻璃胶囊，二次模糊 + 烟熏 + 内阴影 |
| 膨胀 / 弹射 | `animateTo` + `curves.springMotion` |
| 彩色背景 | 预渲染 PNG 光斑，缓慢漂移 |
| 沉浸式 | 全屏 + `getWindowAvoidArea` 安全区 |

选中切换：透镜先在 170 ms 内膨胀到 `1.20 × 1.26`，同时用 `springMotion(0.42, 0.7)` 在 640 ms 内弹到目标标签，再在 520 ms 内回弹收窄。

## 目录

```
entry/src/main/ets/
├── pages/Index.ets                 # 页面、滚动内容、安全区
└── components/
    ├── LiquidTabBar.ets            # 液态玻璃 TabBar
    ├── GlassRim.ets                # Canvas 镜面描边 / 色散
    └── AuroraBackground.ets        # 漂移彩色背景

entry/src/main/resources/base/media/
├── tab_today.svg / tab_game.svg / tab_apps.svg / tab_search.svg
├── blob_*.png                      # 背景光斑
└── glow_white.png                  # 切换 bloom
```

详细拆解、尺寸测量、动效参数与还原度对照见 **[docs/analysis.md](docs/analysis.md)**。

## 运行

```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon assembleHap

hdc -t 127.0.0.1:5555 install -r \
  entry/build/default/outputs/default/entry-default-unsigned.hap

hdc -t 127.0.0.1:5555 shell aa start \
  -a EntryAbility -b io.xuxiaowei.liquidglass
```

> 模拟器已开启开发者模式，可直接安装未签名 HAP。DevEco 自动生成的 `entry-default-signed.hap` 用于真机签名环境；当前模拟器与自动签名信息不一致，安装会报 `install sign info inconsistent`，因此模拟器调试使用未签名包。

## 操作

- 上下滚动：把彩色卡片滑到导航栏下方，观察取色、模糊与高光变化。
- 点击四个标签：观察透镜的膨胀、弹射和回弹。
- 按住标签不松手：整条玻璃栏在 260ms 内放大到 **1.05×**，图标同时缩到 0.86；松开后 360ms 弹回。

## 已知差异

- iOS 的选中透镜会**真实折射并放大**下方内容；ArkUI API 20 没有背景位移采样能力，本项目用增饱和、烟熏色调、镜面描边与色散边做近似。
- 字体为 HarmonyOS Sans，而非 SF Pro。
- 系统 Home Indicator 样式由模拟器决定。
