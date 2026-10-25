/**
 * GlassRim
 *
 * Draws the optical "edge" of a piece of liquid glass:
 *  - a bright specular rim that is strongest on the upper-left shoulder
 *  - a softer reflected rim along the lower edge
 *  - an inner sheen that suggests glass thickness
 *  - optional cyan / amber dispersion fringes (the colour split you see at the
 *    edge of a real lens)
 *
 * The component is purely decorative, it never takes touches.
 */
@Component
export struct GlassRim {
  @Prop rimW: number = 100;
  @Prop rimH: number = 60;
  @Prop rimR: number = 30;
  @Prop chromatic: boolean = false;
  @Prop sheen: number = 0.5;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private roundedPath(x: number, y: number, w: number, h: number, r: number): void {
    const ctx = this.ctx;
    const rr: number = Math.max(0, Math.min(r, Math.min(w, h) / 2));
    ctx.beginPath();
    ctx.moveTo(x + rr, y);
    ctx.lineTo(x + w - rr, y);
    ctx.arc(x + w - rr, y + rr, rr, -Math.PI / 2, 0);
    ctx.lineTo(x + w, y + h - rr);
    ctx.arc(x + w - rr, y + h - rr, rr, 0, Math.PI / 2);
    ctx.lineTo(x + rr, y + h);
    ctx.arc(x + rr, y + h - rr, rr, Math.PI / 2, Math.PI);
    ctx.lineTo(x, y + rr);
    ctx.arc(x + rr, y + rr, rr, Math.PI, Math.PI * 1.5);
    ctx.closePath();
  }

  private draw(): void {
    const ctx = this.ctx;
    const w: number = this.rimW;
    const h: number = this.rimH;
    const r: number = Math.min(this.rimR, h / 2);
    if (w <= 0 || h <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);

    // --- main specular rim -------------------------------------------------
    const rim = ctx.createLinearGradient(0, 0, w * 0.45, h);
    rim.addColorStop(0, 'rgba(255,255,255,0.90)');
    rim.addColorStop(0.18, 'rgba(255,255,255,0.55)');
    rim.addColorStop(0.42, 'rgba(255,255,255,0.12)');
    rim.addColorStop(0.66, 'rgba(255,255,255,0.16)');
    rim.addColorStop(0.86, 'rgba(255,255,255,0.38)');
    rim.addColorStop(1, 'rgba(255,255,255,0.72)');
    ctx.strokeStyle = rim;
    ctx.lineWidth = 1.0;
    this.roundedPath(0.45, 0.45, w - 0.9, h - 0.9, r - 0.4);
    ctx.stroke();

    // --- thin lower reflected line (the "second highlight") ---------------
    ctx.save();
    this.roundedPath(0, 0, w, h, r);
    ctx.clip();
    const low = ctx.createLinearGradient(0, h * 0.55, 0, h);
    low.addColorStop(0, 'rgba(255,255,255,0)');
    low.addColorStop(1, 'rgba(255,255,255,0.24)');
    ctx.strokeStyle = low;
    ctx.lineWidth = 1.7;
    this.roundedPath(1.8, 1.8, w - 3.6, h - 3.6, r - 1.8);
    ctx.stroke();
    ctx.restore();

    // --- chromatic dispersion --------------------------------------------
    if (this.chromatic) {
      const dispersion = ctx.createLinearGradient(0, 0, w, h);
      dispersion.addColorStop(0, 'rgba(110,235,255,0.68)');
      dispersion.addColorStop(0.28, 'rgba(110,235,255,0.10)');
      dispersion.addColorStop(0.62, 'rgba(255,214,120,0.10)');
      dispersion.addColorStop(1, 'rgba(255,178,120,0.62)');
      ctx.strokeStyle = dispersion;
      ctx.lineWidth = 1.5;
      this.roundedPath(1.6, 1.6, w - 3.2, h - 3.2, r - 1.6);
      ctx.stroke();
    }

    // --- soft sheen inside the top-left shoulder --------------------------
    if (this.sheen > 0) {
      ctx.save();
      this.roundedPath(1.2, 1.2, w - 2.4, h - 2.4, r - 1.2);
      ctx.clip();
      const sheen = ctx.createRadialGradient(w * 0.30, h * 0.02, 0, w * 0.30, h * 0.02, w * 0.52);
      sheen.addColorStop(0, `rgba(255,255,255,${0.30 * this.sheen})`);
      sheen.addColorStop(0.45, `rgba(255,255,255,${0.08 * this.sheen})`);
      sheen.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = sheen;
      ctx.fillRect(0, 0, w, h);
      ctx.restore();
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .onReady(() => {
        this.draw();
      })
  }
}
