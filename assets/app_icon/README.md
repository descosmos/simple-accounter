# 简账 App 图标

以 Android 真机上的首页和「记一笔」页面截图作为风格参考。图标使用暖白背景、炭黑细线方框、点阵 ¥ 和右上角小橙点，呼应 `lib/theme.dart` 的纸张配色、`EinkDots` 金额字体和记账按钮。

- 设计原图：`app_icon.png`，由内置 imagegen 生成；保留完整暖白背景，无透明通道。
- Android：五组传统 launcher 尺寸，以及带独立背景和 8% 前景内边距的 adaptive icon。
- iOS：沿用现有 AppIcon asset catalog 的全部尺寸，包含 1024 × 1024 商店图标。
- 重新生成平台资源（macOS 自带 sips）：`bash tool/generate_app_icons.sh`。
- Android 留白参考：[Adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)。

## 最终生成提示词

工具：内置 imagegen。两张输入图是实际 App 首页与记账页的截图，仅用作视觉风格参考。

```text
Use case: logo-brand
Asset type: a final single square mobile launcher icon for 简账, a Chinese minimalist local bookkeeping Flutter app.
Input images: Image 1 is an actual app HOME SCREEN screenshot, STYLE REFERENCE ONLY. Image 2 is an actual RECORD ENTRY screen screenshot, STYLE REFERENCE ONLY. These are not edit targets. Create a new standalone icon artwork. Do not include any screenshot or phone frame in the output.
Primary request: Make the app icon feel like an exact member of the visual system visible in the screenshots: warm ivory e-paper background, restrained thin charcoal rounded-square outlines, one prominent stepped pixel-font currency symbol, and a tiny orange indicator dot just like the orange dot on the app's bottom-center record button and selected category.
Composition: 1024 x 1024 square, perfectly flat uniform opaque warm paper #F4F2EC fills the entire canvas, including all four corners. Center a SINGLE modestly rounded SQUARE charcoal outline, approximately 540 x 540 pixels (from x242 to782 and y242 to782), corner radius about 65px, uniform thin 12px stroke in #1C1C1A, no fill difference from the canvas. This inner outline is part of the logo, not an outer app tile.
Inside this outline: a SINGLE large centered charcoal yen/yuan currency glyph '¥', drawn with crisp stepped square pixels like the VT323 terminal-style currency glyph visible next to 0.00 on the screenshot. Its outer silhouette must unmistakably read as ¥, with two diagonal upper arms, a vertical lower stem and TWO horizontal crossbars. Approximately 235px wide by 280px tall. The glyph is the main dark visual focal point. Use square blocks and stepped edges, not round dot-matrix dots, and not a smooth typeface. Keep it centered horizontally and vertically.
At the upper-right corner of the outline place ONE small flat orange #E35F2D circular indicator, diameter about 42px, optically centered near (774,242). Leave a tiny warm-paper knockout around the orange dot so it reads separately from the charcoal line, exactly like the small orange dot on the reference app's record button. Orange must occupy far less than 1% of the canvas area.
Style: truly flat, sparse, precise, quiet warm e-ink industrial minimalism. The drawing should visually belong alongside the thin framed keys and category tiles in the reference screenshots. Generous empty paper around and inside the symbol. No heavy black panels, no book spine, no orange bookmark, no large color patches.
Text: only the single ¥ glyph; no words, no Chinese characters, no letters, no numerals, no captions.
Constraints: solid flat colors only, no shadows whatsoever, no gradients, no shine, no 3D volume, no texture or noise, no photographic rendering, no perspective. NO black backdrop and NO transparency: every background pixel is opaque warm ivory. Do not pre-mask or round the outside square canvas. No icon grid, no mockups, no extra border around the image. Deliver only ONE finished square icon.
```
