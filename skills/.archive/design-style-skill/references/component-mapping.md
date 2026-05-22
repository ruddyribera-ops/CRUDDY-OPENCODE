# 组件级风格映射表

| 组件 | Sharp | Soft | Rounded | Pill |
|---|---|---|---|---|
| **按钮/标签** | rectRadius: 0 | rectRadius: 0.05 | rectRadius: 0.1 | rectRadius: 0.2 |
| **卡片/容器** | rectRadius: 0.03 | rectRadius: 0.1 | rectRadius: 0.2 | rectRadius: 0.3 |
| **图片容器** | rectRadius: 0 | rectRadius: 0.08 | rectRadius: 0.15 | rectRadius: 0.25 |
| **输入框形状** | rectRadius: 0 | rectRadius: 0.05 | rectRadius: 0.1 | rectRadius: 0.2 |
| **徽章/Badge** | rectRadius: 0.02 | rectRadius: 0.05 | rectRadius: 0.08 | rectRadius: 0.15 |
| **头像框** | rectRadius: 0 | rectRadius: 0.1 | rectRadius: 0.2 | rectRadius: 0.5 (圆形) |

## PptxGenJS 圆角示例

```javascript
// Sharp 风格卡片
slide.addShape("rect", {
  x: 0.5, y: 1, w: 4, h: 2.5,
  fill: { color: "F5F5F5" },
  rectRadius: 0.03
});

// Rounded 风格卡片
slide.addShape("rect", {
  x: 0.5, y: 1, w: 4, h: 2.5,
  fill: { color: "F5F5F5" },
  rectRadius: 0.2
});

// Pill 风格按钮 (高度0.4"时，rectRadius设为0.2"即为胶囊形)
slide.addShape("rect", {
  x: 3, y: 4, w: 2, h: 0.4,
  fill: { color: "4A90D9" },
  rectRadius: 0.2
});
```
