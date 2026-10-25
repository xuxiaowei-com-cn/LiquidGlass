/**
 * GlassRim
 *
 * Draws the optical edge of a piece of liquid glass:
 *  - a 1 px dark contact line, so the glass still reads as an object on white
 *  - a thin specular rim that is bright along the top and bottom edges and
 *    almost disappears along the sides (that is what makes it look like a
 *    polished edge instead of a painted border)
 *  - a second, softer reflected line just inside the bottom lip
 *  - optional cyan / amber dispersion fringes (the colour split you see at the
 *    edge of a real lens)
 *  - a soft sheen in the upper-left shoulder
 *
 * `strength` dials the whole specular layer up or down. The selected lens uses
 * a low strength while it is at rest and a full-strength, chromatic rim while
 * it is moving, which is exactly what the reference recording shows.
 *
 * The rim is painted once in `onReady`. Callers only ever transform the
 * component (translate / scale / opacity), never re-size it mid-animation, so
 * the 0.5 vp lines stay crisp instead of being re-rasterised every frame while
 * the lens travels or blooms.
 *
 * The component is purely decorative, it never takes touches.
 */
@Component
export struct GlassRim {
  @Prop rimW: number = 100;
  @Prop rimH: number = 60;
  @Prop rimR: number = 30;
  @Prop strength: number = 1;
  @Prop darkEdge: number = 0.12;
  @Prop chromatic: boolean = false;
  @Prop sheen: number = 0;
  @Prop glint: number = 1;
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
    const s: number = Math.max(0, Math.min(1, this.strength));
    if (w <= 0 || h <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);

    // --- dark contact line ------------------------------------------------
    // A real glass edge is first a slightly darker line where the light bends
    // away, then a bright line where it comes back. Without the dark line the
    // bar turns into a white outline over white content.
    if (this.darkEdge > 0) {
      ctx.strokeStyle = `rgba(12,14,18,${this.darkEdge})`;
      ctx.lineWidth = 0.5;
      this.roundedPath(0.25, 0.25, w - 0.5, h - 0.5, r - 0.25);
      ctx.stroke();
    }

    // --- main specular rim ------------------------------------------------
    // Vertical gradient: hot along the upper and lower lip, almost nothing in
    // the middle of the sides. This is the single most important line of the
    // material.
    if (s > 0) {
      const rim = ctx.createLinearGradient(0, 0, 0, h);
      rim.addColorStop(0, `rgba(255,255,255,${0.96 * s})`);
      rim.addColorStop(0.07, `rgba(255,255,255,${0.76 * s})`);
      rim.addColorStop(0.18, `rgba(255,255,255,${0.34 * s})`);
      rim.addColorStop(0.36, `rgba(255,255,255,${0.10 * s})`);
      rim.addColorStop(0.58, `rgba(255,255,255,${0.08 * s})`);
      rim.addColorStop(0.78, `rgba(255,255,255,${0.22 * s})`);
      rim.addColorStop(0.92, `rgba(255,255,255,${0.56 * s})`);
      rim.addColorStop(1, `rgba(255,255,255,${0.92 * s})`);
      ctx.strokeStyle = rim;
      ctx.lineWidth = 0.5;
      this.roundedPath(0.8, 0.8, w - 1.6, h - 1.6, r - 0.8);
      ctx.stroke();
    }

    // --- thin lower reflected line (the "second highlight") ---------------
    ctx.save();
    this.roundedPath(0, 0, w, h, r);
    ctx.clip();
    const low = ctx.createLinearGradient(0, h * 0.5, 0, h);
    low.addColorStop(0, 'rgba(255,255,255,0)');
    low.addColorStop(1, `rgba(255,255,255,${0.26 * Math.max(s, 0.4)})`);
    ctx.strokeStyle = low;
    ctx.lineWidth = 0.9;
    this.roundedPath(2.0, 2.0, w - 4.0, h - 4.0, Math.max(0, r - 2.0));
    ctx.stroke();

    // --- top inner glint --------------------------------------------------
    // A crisp, short reflection that only lives on the upper lip.
    if (s > 0.3 && this.glint > 0) {
      ctx.save();
      ctx.beginPath();
      ctx.rect(0, 0, w, h * 0.24);
      ctx.clip();
      ctx.strokeStyle = `rgba(255,255,255,${0.34 * s * this.glint})`;
      ctx.lineWidth = 1.1;
      this.roundedPath(2.2, 2.2, w - 4.4, h - 4.4, Math.max(0, r - 2.2));
      ctx.stroke();
      ctx.restore();
    }
    ctx.restore();

    // --- chromatic dispersion --------------------------------------------
    if (this.chromatic && s > 0.2) {
      const fringe = ctx.createLinearGradient(0, 0, w, h);
      fringe.addColorStop(0, `rgba(112,236,255,${0.78 * s})`);
      fringe.addColorStop(0.18, `rgba(150,255,246,${0.20 * s})`);
      fringe.addColorStop(0.46, 'rgba(255,255,255,0)');
      fringe.addColorStop(0.70, `rgba(255,196,255,${0.20 * s})`);
      fringe.addColorStop(0.88, `rgba(255,206,138,${0.38 * s})`);
      fringe.addColorStop(1, `rgba(255,168,96,${0.70 * s})`);
      ctx.strokeStyle = fringe;
      ctx.lineWidth = 1.05;
      this.roundedPath(1.5, 1.5, w - 3.0, h - 3.0, r - 1.5);
      ctx.stroke();

      // a second, wider fringe reads as the light splitting through the glass
      ctx.strokeStyle = fringe;
      ctx.lineWidth = 1.9;
      ctx.globalAlpha = 0.30;
      this.roundedPath(2.6, 2.6, w - 5.2, h - 5.2, Math.max(0, r - 2.6));
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    // --- soft sheen inside the top-left shoulder --------------------------
    if (this.sheen > 0) {
      ctx.save();
      this.roundedPath(1.2, 1.2, w - 2.4, h - 2.4, r - 1.2);
      ctx.clip();
      const sheen = ctx.createRadialGradient(w * 0.28, h * 0.02, 0, w * 0.28, h * 0.02, w * 0.50);
      sheen.addColorStop(0, `rgba(255,255,255,${0.34 * this.sheen})`);
      sheen.addColorStop(0.42, `rgba(255,255,255,${0.10 * this.sheen})`);
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
