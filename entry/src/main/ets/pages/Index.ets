import { window } from '@kit.ArkUI';
import { AuroraBackground } from '../components/AuroraBackground';
import { LiquidTabBar } from '../components/LiquidTabBar';

/**
 * The demo page behind the liquid-glass bar.
 *
 * It exists to give the glass something worth showing through: a drifting
 * aurora wallpaper, a scrolling column of saturated cards, a warm scrim under
 * the status bar and the floating tab bar. The page reads the system insets
 * once and uses them for that scrim, for the content's bottom padding and for
 * the bar's distance from the home indicator.
 */
@Entry
@Component
struct Index {
  @State selected: number = 0;
  @State safeTop: number = 28;
  @State safeBottom: number = 10;
  private scroller: Scroller = new Scroller();

  // Per-tab copy: the page is the same everywhere, only these strings and the
  // hero gradient change, which makes the tab switch easy to read.
  private tabTitles: string[] = ['Today', '游戏', 'App', '搜索'];
  private kickers: string[] = ['LIQUID GLASS', 'PLAY', 'DISCOVER', 'FIND'];
  private heroTitles: string[] = [
    '液态玻璃\n流动的界面',
    '为触感\n而生的玻璃',
    '内容在\n玻璃下呼吸',
    '让背景\n成为界面'
  ];
  private heroSubs: string[] = [
    'iOS 27 底部导航栏的材质与动效研究',
    '光、影与折射在指尖融化',
    '一层会呼吸的玻璃，托住内容',
    '模糊、取色与高光，都在此刻'
  ];
  private heroGradients: string[][] = [
    ['#FF9A62', '#FF4E7A', '#9C5CFF'],
    ['#4F8CFF', '#7B5CFF', '#FF5CA8'],
    ['#00C2A8', '#2E8BFF', '#8A5CFF'],
    ['#F7B733', '#FC4A1A', '#FF7EB6']
  ];

  /** Reads the status bar / home indicator insets so the page can stay clear. */
  aboutToAppear(): void {
    const host = this.getUIContext().getHostContext();
    if (!host) {
      return;
    }
    window.getLastWindow(host).then((win: window.Window) => {
      try {
        const sys = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const nav = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        const uiCtx = this.getUIContext();
        const top: number = uiCtx.px2vp(sys.topRect.height);
        const bottom: number = Math.max(
          uiCtx.px2vp(sys.bottomRect.height),
          uiCtx.px2vp(nav.bottomRect.height),
          8
        );
        if (top > 0) {
          this.safeTop = top;
        }
        this.safeBottom = bottom;
      } catch (err) {
        // keep fallbacks
      }
    });
  }

  /** Date, the current tab's title and the avatar badge. */
  @Builder
  Header() {
    Row() {
      Column() {
        Text('10月25日 星期日')
          .fontSize(12.5)
          .fontColor('#77777E')
          .letterSpacing(0.3)
        Text(this.tabTitles[this.selected])
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111114')
          .letterSpacing(-0.8)
          .margin({ top: 1 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Stack() {
        Circle()
          .width(40)
          .height(40)
          .fill('#33FFFFFF')
        Circle()
          .width(40)
          .height(40)
          .fill('#1A9C5CFF')
        Text('L')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .clip(true)
      .border({ width: 1, color: '#7AFFFFFF' })
      .shadow({ radius: 10, color: '#26000000', offsetY: 4 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)

    Row({ space: 6 }) {
      Circle()
        .width(6)
        .height(6)
        .fill('#0A84FF')
      Text('Liquid Glass 交互实验')
        .fontSize(11)
        .fontColor('#5C5C66')
        .letterSpacing(0.2)
    }
    .margin({ top: 8, bottom: 18 })
  }

  /**
   * The hero artwork: a per-tab gradient, a few glass bubbles and a miniature
   * echo of the real bar. Repeated once at the very bottom of the page.
   */
  @Builder
  HeroCard() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [this.heroGradients[this.selected][0], 0],
            [this.heroGradients[this.selected][1], 0.56],
            [this.heroGradients[this.selected][2], 1]
          ]
        })

      // soft glass bubbles in the artwork
      Circle()
        .width(230)
        .height(230)
        .fill('#26FFFFFF')
        .position({ x: 200, y: -66 })
      Circle()
        .width(120)
        .height(120)
        .fill('#1FFFFFFF')
        .position({ x: 268, y: 66 })
      Circle()
        .width(58)
        .height(58)
        .fill('#33FFFFFF')
        .position({ x: 190, y: 118 })
        .stroke('#66FFFFFF')
        .strokeWidth(1)

      // miniature glass bar, an echo of the real thing
      Row({ space: 8 }) {
        Circle().width(5).height(5).fill('#66FFFFFF')
        Circle().width(5).height(5).fill('#FFFFFFFF')
        Circle().width(5).height(5).fill('#66FFFFFF')
        Circle().width(5).height(5).fill('#66FFFFFF')
      }
      .width(86)
      .height(28)
      .justifyContent(FlexAlign.Center)
      .borderRadius(14)
      .backgroundColor('#2EFFFFFF')
      .border({ width: 0.8, color: '#80FFFFFF' })
      .position({ x: 212, y: 146 })

      Column() {
        Text(this.kickers[this.selected])
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E6FFFFFF')
          .letterSpacing(1.6)
        Text(this.heroTitles[this.selected])
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .lineHeight(32)
          .margin({ top: 7 })
        Text(this.heroSubs[this.selected])
          .fontSize(11.5)
          .fontColor('#D9FFFFFF')
          .margin({ top: 7 })
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .width('62%')
      .padding({ left: 22, right: 10, bottom: 22 })
    }
    .width('100%')
    .height(196)
    .borderRadius(28)
    .clip(true)
    .shadow({
      radius: 24,
      color: '#3D5A2A6E',
      offsetX: 0,
      offsetY: 14
    })
  }

  /** Section heading with a small English caption on the right. */
  @Builder
  SectionTitle(title: string, caption: string) {
    Row() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151519')
      Blank()
      Text(caption)
        .fontSize(10.5)
        .fontColor('#85858D')
        .letterSpacing(0.4)
    }
    .width('100%')
    .margin({ top: 26, bottom: 11 })
  }

  /** One of the three material stats under 材质拆解. */
  @Builder
  StatCard(value: string, label: string, tint: string) {
    Column() {
      Text(value)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(tint)
        .letterSpacing(-0.4)
      Text(label)
        .fontSize(10)
        .fontColor('#707078')
        .margin({ top: 4 })
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(82)
    .justifyContent(FlexAlign.Center)
    .borderRadius(18)
    .backgroundColor('#7AFFFFFF')
    .border({ width: 1, color: '#B3FFFFFF' })
    .shadow({ radius: 12, color: '#14000000', offsetY: 5 })
  }

  /** A swatch in the horizontal 取色样本 strip. */
  @Builder
  ColorCard(title: string, from: string, to: string) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [from, 0],
            [to, 1]
          ]
        })
      Circle()
        .width(90)
        .height(90)
        .fill('#26FFFFFF')
        .position({ x: 118, y: -22 })
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .padding({ left: 16, bottom: 14 })
    }
    .width(196)
    .height(118)
    .borderRadius(22)
    .clip(true)
    .border({ width: 1, color: '#40FFFFFF' })
    .shadow({ radius: 16, color: '#26000000', offsetY: 8 })
  }

  /** A row in 观察要点: round glyph, title and one line of explanation. */
  @Builder
  InsightRow(glyph: string, title: string, desc: string, tint: string) {
    Row({ space: 13 }) {
      Stack() {
        Circle()
          .width(40)
          .height(40)
          .fill(tint)
        Text(glyph)
          .fontSize(17)
          .fontColor('#FFFFFF')
      }
      .width(40)
      .height(40)

      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#16161A')
        Text(desc)
          .fontSize(11)
          .fontColor('#74747C')
          .margin({ top: 3 })
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(20)
    .backgroundColor('#57FFFFFF')
    .border({ width: 1, color: '#8CFFFFFF' })
    .margin({ bottom: 10 })
  }

  /**
   * The closing card. Its large `LIQUID GLASS` watermark is the easiest thing
   * to park under the bar to judge the glass' transparency.
   */
  @Builder
  ClosingCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#2E6BFF', 0],
            ['#7B5CFF', 0.55],
            ['#FF5CA8', 1]
          ]
        })
      Circle()
        .width(180)
        .height(180)
        .fill('#26FFFFFF')
        .position({ x: 210, y: -50 })
      Circle()
        .width(90)
        .height(90)
        .fill('#33FFFFFF')
        .position({ x: 250, y: 70 })
      Column() {
        Text('色彩，在玻璃下流动')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('把这张卡片滑到导航栏下方，观察取色与模糊')
          .fontSize(11)
          .fontColor('#D9FFFFFF')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 22, top: 24, right: 120 })

      Text('↓')
        .fontSize(18)
        .fontColor('#CCFFFFFF')
        .position({ x: 296, y: 34 })

      // large watermark that ends up under the glass when the card is
      // scrolled to the bottom; it makes the bar's see-through quality
      // easy to judge
      Text('LIQUID GLASS')
        .fontSize(38)
        .fontWeight(FontWeight.Bold)
        .fontColor('#D9FFFFFF')
        .letterSpacing(4)
        .position({ x: 22, y: 140 })
    }
    .width('100%')
    .height(196)
    .borderRadius(26)
    .clip(true)
    .margin({ top: 8, bottom: 4 })
    .shadow({ radius: 20, color: '#33351E75', offsetY: 10 })
  }

  /** The scrollable column behind the bar. */
  @Builder
  Content() {
    Column() {
      this.Header()
      this.HeroCard()

      this.SectionTitle('材质拆解', 'MATERIAL')
      Row({ space: 9 }) {
        this.StatCard('0vp', '无模糊', '#0A84FF')
        this.StatCard('1px', '镜面描边', '#FF6B8A')
        this.StatCard('4%', '顶部白霜', '#8A5CFF')
      }
      .width('100%')

      this.SectionTitle('取色样本', 'TINT')
      Scroll() {
        Row({ space: 12 }) {
          this.ColorCard('落日', '#FFB062', '#FF4E7A')
          this.ColorCard('深海', '#2E6BFF', '#66E0FF')
          this.ColorCard('薄荷', '#19C79B', '#C6F36B')
          this.ColorCard('紫罗兰', '#8A5CFF', '#FF7AD9')
        }
        .padding({ right: 20 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(118)
      .edgeEffect(EdgeEffect.Spring)

      this.SectionTitle('观察要点', 'DETAILS')
      this.InsightRow('◐', '背景透明', '滚动页面，导航栏直接透出下方的内容与文字', '#3E7BFF')
      this.InsightRow('◇', '取色与增饱和', '彩色卡片经过玻璃时，颜色被晕开、提亮并保留', '#FF6B8A')
      this.InsightRow('✧', '边缘折射', '顶部白霜、底部反光与青琥珀色散共同塑造厚度', '#8A5CFF')

      this.ClosingCard()

      // repeat the page's hero card once at the very bottom
      Column() {
        this.HeroCard()
      }
      .width('100%')
      .margin({ top: 18 })
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: this.safeTop + 14,
      bottom: 36 + this.safeBottom
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AuroraBackground()

      Scroll(this.scroller) {
        this.Content()
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')

      // A warm scrim that keeps the status bar readable while content slides
      // underneath it (the page itself is full-screen / edge-to-edge).
      Column()
        .width('100%')
        .height(this.safeTop + 40)
        .linearGradient({
          angle: 180,
          colors: [
            ['#E6FBF7F0', 0],
            ['#66FBF7F0', 0.55],
            ['#00FBF7F0', 1]
          ]
        })
        .position({ x: 0, y: 0 })
        .hitTestBehavior(HitTestMode.None)

      // 17 vp above the home indicator on gesture-nav devices; three-button
      // navigation lifts the bar above the safe area instead.
      LiquidTabBar({ selected: $selected })
        .margin({ bottom: Math.max(17, this.safeBottom - 17) })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
