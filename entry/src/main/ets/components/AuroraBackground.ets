/**
 * AuroraBackground
 *
 * A soft, slowly breathing wallpaper that gives the liquid glass something
 * worth refracting: saturated colour fields, large soft falloffs and plenty of
 * movement behind the bottom bar.
 *
 * The colour fields are pre-rendered PNG falloffs instead of runtime gradients
 * so that they stay band-free on every GPU and can be composited cheaply while
 * they drift.
 */
@Component
export struct AuroraBackground {
  @State private moved: boolean = false;

  aboutToAppear(): void {
    setTimeout(() => {
      this.moved = true;
    }, 150);
  }

  @Builder
  Blob(src: Resource, diameter: number, x: number, y: number, dx: number, dy: number,
    duration: number, opacity: number) {
    Image(src)
      .width(diameter)
      .height(diameter)
      .objectFit(ImageFit.Fill)
      .interpolation(ImageInterpolation.High)
      .position({ x: x, y: y })
      .translate({ x: this.moved ? dx : 0, y: this.moved ? dy : 0 })
      .opacity(opacity)
      .animation({
        duration: duration,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      })
      .hitTestBehavior(HitTestMode.None)
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 168,
          colors: [
            ['#FFF9EF', 0],
            ['#F8F3FF', 0.34],
            ['#FFF3F6', 0.66],
            ['#F1F6FF', 1]
          ]
        })

      this.Blob($r('app.media.blob_orange'), 520, -150, 300, 46, -26, 17000, 0.9)
      this.Blob($r('app.media.blob_blue'), 600, 120, 500, -52, 24, 21000, 1.0)
      this.Blob($r('app.media.blob_violet'), 520, -110, 620, 58, -18, 15500, 1.0)
      this.Blob($r('app.media.blob_pink'), 440, 190, 660, -36, 30, 19000, 0.92)
      this.Blob($r('app.media.blob_mint'), 360, 10, 80, 42, 18, 23500, 0.8)
    }
    .width('100%')
    .height('100%')
  }
}
