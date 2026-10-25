import { curves } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { GlassRim } from './GlassRim';

const TAB_COUNT: number = 4;
const BAR_HEIGHT: number = 60;
const SIDE_MARGIN: number = 22;
const ITEM_GAP: number = 10;
const UNSELECTED_INK: string = '#141418';
const SELECTED_BLUE: string = '#0A84FF';

/**
 * A floating "liquid glass" tab bar modelled after the iOS 27 App Store bar
 * shown in the reference recording.
 *
 * Layers, bottom to top:
 *   1. bloom halo          – soft light that escapes the bar while a tab is hit
 *   2. glass base          – real backdrop blur + a white "thickness" gradient
 *                            that is milky at the top and clear at the bottom
 *   3. glass rim           – 1px specular edge, lower reflected line, sheen
 *   4. selection lens      – a clear, slightly darker glass capsule with a
 *                            chromatic rim; it inflates and springs to the
 *                            tapped item
 *   5. icons + labels      – crisp, always on top of the glass
 */
@Component
export struct LiquidTabBar {
  @Link selected: number;
  @State private barW: number = 342;
  @State private bloomX: number = 1;
  @State private bloomY: number = 1;
  @State private glow: number = 0;
  @State private pressed: number = -1;
  @State private bubbleX: number = 5;
  @State private barScale: number = 1;
  @State private lensFill: number = 1;
  @State private lensRim: number = 1;
  private barH: number = BAR_HEIGHT;
  private tapSeq: number = 0;
  private downX: number = 0;
  private downY: number = 0;
  private lastSelectAt: number = 0;

  aboutToAppear(): void {
    try {
      const screenWidthVp: number = this.getUIContext().px2vp(display.getDefaultDisplaySync().width);
      const computed: number = screenWidthVp - SIDE_MARGIN * 2;
      if (computed > 200) {
        this.barW = computed;
      }
    } catch (err) {
      this.barW = 342;
    }
    this.bubbleX = this.tabW() * this.selected + ITEM_GAP / 2;
  }

  private tabW(): number {
    return this.barW / TAB_COUNT;
  }

  private bubbleW(): number {
    return this.tabW() - ITEM_GAP;
  }

  private bubbleH(): number {
    return this.barH - 10;
  }

  /**
   * Magnifies only the bar's own icons/labels around the travelling lens.
   * The page behind the bar is never scaled.
   */
  private itemMagnify(index: number): number {
    const bubbleCenter: number = this.bubbleX + this.bubbleW() / 2;
    const itemCenter: number = this.tabW() * (index + 0.5);
    const distance: number = Math.abs(itemCenter - bubbleCenter);
    const radius: number = this.tabW() * 1.5;
    const influence: number = Math.max(0, 1 - distance / radius);
    const bloom: number = Math.max(0, Math.min(1, (this.bloomX - 1) / 0.45));
    return 1 + influence * bloom * 0.34;
  }

  private settleBloom(seq: number): void {
    setTimeout(() => {
      if (seq !== this.tapSeq) {
        return;
      }
      this.getUIContext().animateTo({
        duration: 520,
        curve: curves.springMotion(0.52, 0.82)
      }, () => {
        this.bloomX = 1;
        this.bloomY = 1;
        this.glow = 0;
        this.lensFill = 1;
        this.lensRim = 1;
      });
    }, 150);
  }

  private releasePress(resetLens: boolean): void {
    const ui = this.getUIContext();
    ui.animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.pressed = -1;
    });
    ui.animateTo({
      duration: 360,
      curve: curves.springMotion(0.42, 0.86)
    }, () => {
      this.barScale = 1;
    });
    if (resetLens) {
      ui.animateTo({
        duration: 380,
        curve: curves.springMotion(0.46, 0.84)
      }, () => {
        this.bloomX = 1;
        this.bloomY = 1;
        this.glow = 0;
        this.lensFill = 1;
        this.lensRim = 1;
      });
    }
  }

  private selectTab(index: number): void {
    const now: number = Date.now();
    if (now - this.lastSelectAt < 320) {
      this.getUIContext().animateTo({
        duration: 380,
        curve: curves.springMotion(0.46, 0.84)
      }, () => {
        this.bloomX = 1;
        this.bloomY = 1;
        this.glow = 0;
        this.lensFill = 1;
        this.lensRim = 1;
      });
      return;
    }
    this.lastSelectAt = now;

    if (index === this.selected) {
      // Tapping the active tab gives the lens a small "breath".
      this.tapSeq++;
      const seq: number = this.tapSeq;
      this.getUIContext().animateTo({ duration: 170, curve: Curve.EaseOut }, () => {
        this.bloomX = 1.35;
        this.bloomY = 1.35;
        this.glow = 0.95;
        this.lensFill = 0.3;
        this.lensRim = 0.8;
      });
      this.settleBloom(seq);
      return;
    }

    this.tapSeq++;
    const seq: number = this.tapSeq;
    const ui = this.getUIContext();
    const targetX: number = this.tabW() * index + ITEM_GAP / 2;

    // Update the active page immediately (a hard cut avoids muddy in-between
    // colours while the gradient changes), then let the lens travel.
    this.selected = index;

    ui.animateTo({ duration: 170, curve: Curve.EaseOut }, () => {
      this.bloomX = 1.35;
      this.bloomY = 1.35;
      this.glow = 0.95;
      this.lensFill = 0.3;
      this.lensRim = 0.8;
    });
    ui.animateTo({
      duration: 640,
      curve: curves.springMotion(0.42, 0.7)
    }, () => {
      this.bubbleX = targetX;
    });
    this.settleBloom(seq);
  }

  @Builder
  TabItem(index: number, label: string, icon: Resource) {
    Column({ space: 3 }) {
      Image(icon)
        .width(23)
        .height(23)
        .fillColor(this.selected === index ? SELECTED_BLUE : UNSELECTED_INK)
        .objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(10)
        .fontWeight(this.selected === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.selected === index ? SELECTED_BLUE : '#3A3A3E')
        .maxLines(1)
    }
    .width('25%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale({
      x: (this.pressed === index ? 0.95 : 1) * this.itemMagnify(index),
      y: (this.pressed === index ? 0.95 : 1) * this.itemMagnify(index)
    })
    .onTouch((event: TouchEvent) => {
      const ui = this.getUIContext();
      if (event.type === TouchType.Down) {
        const p = event.touches[0];
        this.downX = p ? p.x : 0;
        this.downY = p ? p.y : 0;

        // Cancel any pending collapse from the previous tap.
        this.tapSeq++;

        // The tab itself dips, while the whole glass bar takes a slow breath.
        ui.animateTo({ duration: 130, curve: Curve.EaseOut }, () => {
          this.pressed = index;
        });
        ui.animateTo({
          duration: 260,
          curve: curves.springMotion(0.32, 0.78)
        }, () => {
          this.barScale = 1.05;
        });
        // While the finger stays down the selection lens keeps swelling,
        // far beyond the bar silhouette.
        ui.animateTo({
          duration: 320,
          curve: curves.springMotion(0.34, 0.7)
        }, () => {
          this.bloomX = 1.45;
          this.bloomY = 1.45;
          this.glow = 1;
          this.lensFill = 0.3;
          this.lensRim = 0.8;
          });
      } else if (event.type === TouchType.Up) {
        const t = event.changedTouches.length > 0 ? event.changedTouches[0] : event.touches[0];
        const dx: number = t ? t.x - this.downX : 0;
        const dy: number = t ? t.y - this.downY : 0;
        const moved: number = Math.sqrt(dx * dx + dy * dy);

        // Select on release as well, so a long press still commits the tab.
        if (moved < 16) {
          this.releasePress(false);
          this.selectTab(index);
        } else {
          this.releasePress(true);
        }
      } else if (event.type === TouchType.Cancel) {
        this.releasePress(true);
      }
    })
    .onClick(() => {
      this.selectTab(index);
    })
    .accessibilityText(label)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // ---------------------------------------------------------------
      // 1. bloom halo (behind everything, so only its outside part shows)
      // ---------------------------------------------------------------
      Image($r('app.media.glow_white'))
        .width(this.tabW() * 2.0)
        .height(this.bubbleH() * 1.8)
        .objectFit(ImageFit.Fill)
        .interpolation(ImageInterpolation.High)
        .position({
          x: this.bubbleX + this.bubbleW() / 2 - this.tabW(),
          y: this.barH / 2 - this.bubbleH() * 0.9
        })
        .opacity(this.glow * 0.62)
        .hitTestBehavior(HitTestMode.None)

      // ---------------------------------------------------------------
      // 2 + 3. the glass base
      // ---------------------------------------------------------------
      Stack() {
        // real-time backdrop blur + vibrancy
        Column()
          .width('100%')
          .height('100%')
          .backgroundEffect({
            radius: 26,
            saturation: 2.0,
            brightness: 1.06
          })

        // "thickness": frosty top, clear middle, reflective bottom lip
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              ['#8CFFFFFF', 0],
              ['#3DFFFFFF', 0.09],
              ['#08FFFFFF', 0.28],
              ['#00FFFFFF', 0.60],
              ['#08FFFFFF', 0.86],
              ['#24FFFFFF', 1]
            ]
          })

        // a whisper of cool tint keeps the white material from going yellow
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#0A8FA8C8')

        GlassRim({
          rimW: this.barW,
          rimH: this.barH,
          rimR: this.barH / 2,
          chromatic: false,
          sheen: 0.8
        })
      }
      .width('100%')
      .height('100%')
      .borderRadius(this.barH / 2)
      .clip(true)
      .shadow({ radius: 20, color: '#14000000', offsetX: 0, offsetY: 9 })

      // ---------------------------------------------------------------
      // 4. the selection lens — it intentionally swells beyond the bar
      // ---------------------------------------------------------------
      Stack() {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundEffect({
              radius: 9,
              saturation: 1.28,
              brightness: 1.02
            })

          // clear lens body, very slightly smoked
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#10000000')

          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 180,
              colors: [
                ['#47FFFFFF', 0],
                ['#12FFFFFF', 0.22],
                ['#00FFFFFF', 0.56],
                ['#12FFFFFF', 0.84],
                ['#38FFFFFF', 1]
              ]
            })

          // inner bottom shade = glass thickness
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 0,
              colors: [
                ['#1A000000', 0],
                ['#00000000', 0.32]
              ]
            })
        }
        .width('100%')
        .height('100%')
        .opacity(this.lensFill)
        .hitTestBehavior(HitTestMode.None)

        Stack() {
          GlassRim({
            rimW: this.bubbleW(),
            rimH: this.bubbleH(),
            rimR: this.bubbleH() / 2,
            chromatic: true,
            sheen: 0.36
          })
        }
        .width('100%')
        .height('100%')
        .opacity(this.lensRim)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(this.bubbleW())
      .height(this.bubbleH())
      .borderRadius(this.bubbleH() / 2)
      .clip(true)
      .position({ x: 0, y: (this.barH - this.bubbleH()) / 2 })
      .translate({ x: this.bubbleX })
      .scale({ x: this.bloomX, y: this.bloomY })
      .hitTestBehavior(HitTestMode.None)

      // ---------------------------------------------------------------
      // 5. icons + labels
      // ---------------------------------------------------------------
      Row() {
        this.TabItem(0, 'Today', $r('app.media.tab_today'))
        this.TabItem(1, '游戏', $r('app.media.tab_game'))
        this.TabItem(2, 'App', $r('app.media.tab_apps'))
        this.TabItem(3, '搜索', $r('app.media.tab_search'))
      }
      .width('100%')
      .height('100%')
    }
    .width(this.barW)
    .height(this.barH)
    .scale({ x: this.barScale, y: this.barScale })
    .hitTestBehavior(HitTestMode.Default)
  }
}
