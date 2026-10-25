import { curves, display } from '@kit.ArkUI';
import { GlassRim } from './GlassRim';

const TAB_COUNT: number = 4;
const BAR_HEIGHT: number = 62;
const SIDE_MARGIN: number = 22;
const LENS_HEIGHT: number = 51;
const LENS_INSET_X: number = 5.5;
const TAB_CONTENT_HALF: number = 15;
/** The bar's glass body: 85% light grey, so ~15% of the page shows through. */
const BAR_GLASS: string = '#D9F0F0F0';
const UNSELECTED_INK: string = '#141418';
const LABEL_INK: string = '#1D1D1F';
const SELECTED_BLUE: string = '#0A84FF';

/**
 * A floating "liquid glass" tab bar modelled after the iOS 27 App Store bar
 * shown in the reference recording.
 *
 * Layers, bottom to top:
 *   1. glass base          – a translucent light-grey fill + a white
 *                            "thickness" gradient that is frosty only along the
 *                            top lip, clear in the middle and faintly
 *                            reflective at the bottom
 *   2. glass rim           – dark contact line + thin specular edge + bottom
 *                            reflection; the white highlight is only hot on
 *                            the top/bottom lips, so it reads as polished glass
 *                            rather than a painted border
 *   3. lens shadow         – a separate capsule that casts the soft shadow the
 *                            settled lens leaves on the bar
 *   4. selection lens      – a wide, shallow capsule (51 × tab width) that is
 *                            a calm smoked-glass pill at rest and a clear,
 *                            chromatic lens while it is being touched or is
 *                            travelling
 *   5. icons + labels      – crisp, always on top of the glass
 *   6. lens tint           – a tab's glyphs blend toward the selection colour
 *                            as the travelling lens reaches it, as if the glass
 *                            itself were tinted; they fade back to ink as the
 *                            lens moves on.
 */
@Component
export struct LiquidTabBar {
  @Link selected: number;
  @State private barW: number = 342;
  @State private bloomX: number = 1;
  @State private bloomY: number = 1;
  @State private lensActive: number = 0;
  @State private pressed: number = -1;
  @State private bubbleX: number = 5.5;
  private barH: number = BAR_HEIGHT;
  private tapSeq: number = 0;
  private downX: number = 0;
  private downY: number = 0;
  private touchActive: boolean = false;
  private lastTouchEnd: number = 0;

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
    this.bubbleX = this.tabW() * this.selected + LENS_INSET_X;
  }

  private tabW(): number {
    return this.barW / TAB_COUNT;
  }

  private bubbleW(): number {
    return this.tabW() - LENS_INSET_X * 2;
  }

  private bubbleH(): number {
    return LENS_HEIGHT;
  }

  /**
   * Vertical scale of the lens and its shadows.
   *
   * The bubble blooms 1.34x / 1.38x while it is hot, and the hot lens is
   * another 2 vp taller on top of that bloom. The extra 2 vp is expressed as
   * a scale (2 / LENS_HEIGHT) rather than as an animated layout height so the
   * Canvas rim can stay exactly as crisp as it is at rest: GlassRim paints
   * once for a 51 vp capsule and afterwards is only transformed.
   */
  private lensScaleY(): number {
    return this.bloomY + this.lensActive * (2 / LENS_HEIGHT);
  }

  /**
   * How strongly the travelling lens colours a tab (0 = ink, 1 = selection
   * blue). The glyph colour follows the glass, not the committed page: only
   * the tab whose icon/label is actually covered by the lens is blue. As soon
   * as the lens leaves the glyphs, even the current tab falls back to ink.
   */
  private tintAmount(index: number): number {
    const lensCenter: number = this.bubbleX + this.bubbleW() / 2;
    const itemCenter: number = this.tabW() * (index + 0.5);
    const distance: number = Math.abs(itemCenter - lensCenter);
    const lensHalf: number = this.bubbleW() * this.bloomX / 2;
    const coverage: number = (lensHalf + TAB_CONTENT_HALF - distance) / (TAB_CONTENT_HALF * 2);
    return Math.max(0, Math.min(1, coverage));
  }

  private hex2(value: number): string {
    const clamped: number = Math.max(0, Math.min(255, Math.round(value)));
    const digits: string = clamped.toString(16);
    return digits.length < 2 ? `0${digits}` : digits;
  }

  private tabColor(index: number, base: string): string {
    const amount: number = this.tintAmount(index);
    if (amount <= 0) {
      return base;
    }
    if (amount >= 1) {
      return SELECTED_BLUE;
    }
    const b: number = parseInt(base.substring(1), 16);
    const t: number = parseInt(SELECTED_BLUE.substring(1), 16);
    const r: number = ((b >> 16) & 0xFF) + (((t >> 16) & 0xFF) - ((b >> 16) & 0xFF)) * amount;
    const g: number = ((b >> 8) & 0xFF) + (((t >> 8) & 0xFF) - ((b >> 8) & 0xFF)) * amount;
    const bl: number = (b & 0xFF) + ((t & 0xFF) - (b & 0xFF)) * amount;
    return `#${this.hex2(r)}${this.hex2(g)}${this.hex2(bl)}`;
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
    const bloom: number = Math.max(0, Math.min(1, (this.bloomX - 1) / 0.32));
    return 1 + influence * bloom * 0.22;
  }

  private clampBubbleX(x: number): number {
    // Keep the same 5.5 vp margin at both ends as at the top/bottom. At the
    // leftmost tab the bar's inner-left arc and the lens's outer-left arc
    // then share a centre, so the gap is uniform around the whole cap.
    const minX: number = LENS_INSET_X;
    const maxX: number = this.barW - this.bubbleW() - LENS_INSET_X;
    return Math.max(minX, Math.min(maxX, x));
  }

  private nearestTabAt(centerX: number): number {
    const raw: number = Math.round((centerX - this.tabW() / 2) / this.tabW());
    return Math.max(0, Math.min(TAB_COUNT - 1, raw));
  }

  /** The lens turns clear and prismatic as soon as it is touched. */
  private wakeLens(): void {
    this.lensActive = 1;
  }

  /**
   * After the lens has landed it slowly settles back into the calm smoked
   * capsule the reference shows at rest.
   */
  private fadeLens(seq: number, delay: number): void {
    setTimeout(() => {
      if (seq !== this.tapSeq) {
        return;
      }
      this.getUIContext().animateTo({ duration: 680, curve: Curve.EaseOut }, () => {
        this.lensActive = 0;
      });
    }, delay);
  }

  private settleBloom(seq: number): void {
    setTimeout(() => {
      if (seq !== this.tapSeq) {
        return;
      }
      this.getUIContext().animateTo({
        duration: 560,
        curve: curves.springMotion(0.52, 0.82)
      }, () => {
        this.bloomX = 1;
        this.bloomY = 1;
      });
      // keep the hot rim through the landing, then let it cool down
      this.fadeLens(seq, 330);
    }, 150);
  }

  private releasePress(resetLens: boolean): void {
    const ui = this.getUIContext();
    ui.animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.pressed = -1;
    });
    if (resetLens) {
      const seq: number = this.tapSeq;
      ui.animateTo({
        duration: 420,
        curve: curves.springMotion(0.46, 0.84)
      }, () => {
        this.bloomX = 1;
        this.bloomY = 1;
        this.bubbleX = this.tabW() * this.selected + LENS_INSET_X;
      });
      this.fadeLens(seq, 300);
    }
  }

  private selectTab(index: number): void {
    if (index === this.selected) {
      // Tapping the active tab gives the lens a small "breath". It also has
      // to flow home: a drag may have left the lens between two tabs while
      // the nearest tab is still this one, and it must never rest halfway.
      this.tapSeq++;
      const seq: number = this.tapSeq;
      const ui = this.getUIContext();
      const homeX: number = this.tabW() * index + LENS_INSET_X;
      this.wakeLens();
      ui.animateTo({ duration: 170, curve: Curve.EaseOut }, () => {
        this.bloomX = 1.34;
        this.bloomY = 1.34;
      });
      ui.animateTo({
        duration: 420,
        curve: curves.springMotion(0.46, 0.84)
      }, () => {
        this.bubbleX = homeX;
      });
      this.settleBloom(seq);
      return;
    }

    this.tapSeq++;
    const seq: number = this.tapSeq;
    const ui = this.getUIContext();
    const targetX: number = this.tabW() * index + LENS_INSET_X;

    // Update the active page immediately (a hard cut avoids muddy in-between
    // colours while the gradient changes), then let the lens travel.
    this.selected = index;
    this.wakeLens();

    ui.animateTo({ duration: 170, curve: Curve.EaseOut }, () => {
      this.bloomX = 1.34;
      this.bloomY = 1.34;
    });
    ui.animateTo({
      duration: 640,
      curve: curves.springMotion(0.42, 0.7)
    }, () => {
      this.bubbleX = targetX;
    });
    this.settleBloom(seq);
  }

  /**
   * One tab's glyphs. Their colour is driven by the glass: the tab under the
   * lens is selection blue, and the previous tab drops back to ink as soon as
   * the lens has moved off its icon/label.
   */
  @Builder
  TabContent(index: number, label: string, icon: Resource) {
    Column({ space: 4 }) {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(this.tabColor(index, UNSELECTED_INK))
        .objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(12)
        .fontWeight(this.selected === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.tabColor(index, LABEL_INK))
        .maxLines(1)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale({
      x: (this.pressed === index ? 0.95 : 1) * this.itemMagnify(index),
      y: (this.pressed === index ? 0.95 : 1) * this.itemMagnify(index)
    })
  }

  @Builder
  TabItem(index: number, label: string, icon: Resource) {
    Stack() {
      this.TabContent(index, label, icon)
    }
    .width('25%')
    .height('100%')
    .onTouch((event: TouchEvent) => {
      const ui = this.getUIContext();
      if (event.type === TouchType.Down) {
        this.touchActive = true;
        const p = event.touches[0];
        this.downX = p ? p.x : 0;
        this.downY = p ? p.y : 0;

        // Cancel any pending collapse from the previous tap.
        this.tapSeq++;
        this.wakeLens();

        // The tab itself dips; the bar body stays put.
        ui.animateTo({ duration: 130, curve: Curve.EaseOut }, () => {
          this.pressed = index;
        });
        // Glide the lens under the finger, then let it swell.
        const barX: number = this.tabW() * index + (p ? p.x : this.tabW() / 2);
        ui.animateTo({ duration: 140, curve: Curve.EaseOut }, () => {
          this.bubbleX = this.clampBubbleX(barX - this.bubbleW() / 2);
        });
        ui.animateTo({
          duration: 320,
          curve: curves.springMotion(0.34, 0.7)
        }, () => {
          this.bloomX = 1.38;
          this.bloomY = 1.38;
        });
      } else if (event.type === TouchType.Move) {
        const t = event.touches[0];
        if (t) {
          const barX: number = this.tabW() * index + t.x;
          this.bubbleX = this.clampBubbleX(barX - this.bubbleW() / 2);
          this.wakeLens();

          const dx: number = t.x - this.downX;
          const dy: number = t.y - this.downY;
          if (Math.sqrt(dx * dx + dy * dy) > 8) {
            this.pressed = -1;
          }
        }
      } else if (event.type === TouchType.Up) {
        const t = event.changedTouches.length > 0 ? event.changedTouches[0] : event.touches[0];
        const dy: number = t ? t.y - this.downY : 0;

        this.touchActive = false;
        this.lastTouchEnd = Date.now();

        if (Math.abs(dy) > 60) {
          // Dragged vertically away from the bar: cancel and flow home.
          this.releasePress(true);
        } else {
          // Snap to the tab nearest the finger, not to a half-finished lens
          // animation, so a quick release can never leave the bubble between
          // two items.
          const centerX: number = t ? this.tabW() * index + t.x : this.bubbleX + this.bubbleW() / 2;
          const nearest: number = this.nearestTabAt(centerX);
          this.releasePress(false);
          this.selectTab(nearest);
        }
      } else if (event.type === TouchType.Cancel) {
        this.touchActive = false;
        this.lastTouchEnd = Date.now();
        this.releasePress(true);
      }
    })
    .onClick(() => {
      // A touch gesture is already resolved by Up; ignore its trailing click.
      if (this.touchActive || Date.now() - this.lastTouchEnd < 400) {
        return;
      }
      this.selectTab(index);
    })
    .accessibilityText(label)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // ---------------------------------------------------------------
      // 1 + 2. the glass base
      // ---------------------------------------------------------------
      Stack() {
        // translucent light-grey glass body, matching the reference bar
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(BAR_GLASS)

        // "thickness": a narrow frosty top lip, a clear body and a faint
        // reflective bottom lip. Keeping most of the body clear is what lets
        // the colour of the page show through the glass.
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              ['#0AFFFFFF', 0],
              ['#08FFFFFF', 0.10],
              ['#05FFFFFF', 0.22],
              ['#03FFFFFF', 0.36],
              ['#02FFFFFF', 0.52],
              ['#01FFFFFF', 0.66],
              ['#01FFFFFF', 0.80],
              ['#02FFFFFF', 0.92],
              ['#08FFFFFF', 1]
            ]
          })

        // a whisper of cool tint keeps the white material from going yellow
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#018FA8C8')

        GlassRim({
          rimW: this.barW,
          rimH: this.barH,
          rimR: this.barH / 2,
          strength: 0.45,
          darkEdge: 0.02,
          chromatic: false,
          sheen: 0.03,
          glint: 0
        })
      }
      .width('100%')
      .height('100%')
      .borderRadius(this.barH / 2)
      .clip(true)
      .shadow({ radius: 12, color: '#0A000000', offsetX: 0, offsetY: 6 })

      // ---------------------------------------------------------------
      // 3. shadow cast by the lens on the bar (and beyond it when the
      //    lens swells past the bar edges)
      // ---------------------------------------------------------------
      Column()
        .width(this.bubbleW())
        .height(this.bubbleH())
        .borderRadius(this.bubbleH() / 2)
        .backgroundColor('#01000000')
        .shadow({ radius: 7, color: '#15000000', offsetX: 0, offsetY: 4 })
        .position({ x: 0, y: (this.barH - this.bubbleH()) / 2 })
        .translate({ x: this.bubbleX })
        .scale({ x: this.bloomX, y: this.lensScaleY() })
        .hitTestBehavior(HitTestMode.None)

      // the lens lifts off the bar while it is hot, casting a wider shadow
      Column()
        .width(this.bubbleW())
        .height(this.bubbleH())
        .borderRadius(this.bubbleH() / 2)
        .backgroundColor('#01000000')
        .shadow({ radius: 15, color: '#28000000', offsetX: 0, offsetY: 7 })
        .position({ x: 0, y: (this.barH - this.bubbleH()) / 2 })
        .translate({ x: this.bubbleX })
        .scale({ x: this.bloomX, y: this.lensScaleY() })
        .opacity(this.lensActive)
        .hitTestBehavior(HitTestMode.None)

      // ---------------------------------------------------------------
      // 4. the selection lens — it intentionally swells beyond the bar
      // ---------------------------------------------------------------
      Stack() {
        Stack() {
          // smoked base, the calm grey pill the reference shows at rest
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#0A000000')

          // thickness: a slightly darker top lip and lower lip
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 180,
              colors: [
                ['#0A000000', 0],
                ['#00000000', 0.36],
                ['#02000000', 0.66],
                ['#08000000', 1]
              ]
            })

          // while hot: the clear, bright glass sheen
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 180,
              colors: [
                ['#52FFFFFF', 0],
                ['#1CFFFFFF', 0.20],
                ['#00FFFFFF', 0.58],
                ['#10FFFFFF', 0.86],
                ['#33FFFFFF', 1]
              ]
            })
            .opacity(this.lensActive)

          // inner bottom shade = glass thickness
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 0,
              colors: [
                ['#1C000000', 0],
                ['#00000000', 0.36]
              ]
            })
            .opacity(0.35 + this.lensActive * 0.65)

          // rest rim: quiet, no dispersion
          Stack() {
            GlassRim({
              rimW: this.bubbleW(),
              rimH: this.bubbleH(),
              rimR: this.bubbleH() / 2,
              strength: 0.12,
              darkEdge: 0.13,
              chromatic: false,
              sheen: 0,
              glint: 0
            })
          }
          .width('100%')
          .height('100%')
          .hitTestBehavior(HitTestMode.None)

          // hot rim: bright specular + cyan/amber dispersion
          Stack() {
            GlassRim({
              rimW: this.bubbleW(),
              rimH: this.bubbleH(),
              rimR: this.bubbleH() / 2,
              strength: 1,
              darkEdge: 0.06,
              chromatic: true,
              sheen: 0.55,
              glint: 1
            })
          }
          .width('100%')
          .height('100%')
          .opacity(this.lensActive)
          .hitTestBehavior(HitTestMode.None)
        }
        .width('100%')
        .height('100%')
        .borderRadius(this.bubbleH() / 2)
        .clip(true)
        .hitTestBehavior(HitTestMode.None)
      }
      .width(this.bubbleW())
      .height(this.bubbleH())
      .borderRadius(this.bubbleH() / 2)
      .position({ x: 0, y: (this.barH - this.bubbleH()) / 2 })
      .translate({ x: this.bubbleX })
      .scale({ x: this.bloomX, y: this.lensScaleY() })
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
    .hitTestBehavior(HitTestMode.Default)
  }
}
