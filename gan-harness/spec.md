# VITALITY — Health Tracking App Dashboard Design

## App Purpose
A premium personal health companion for Koreans tracking diet, exercise, body measurements, and wellness goals daily.

## Brand DNA (must honor exactly)
**Color tokens:**
- `--brand-primary: #0F3B24` — deepest forest (hero backdrop base)
- `--brand-secondary: #2D6A4F` — mid-forest
- `--brand-accent: #52B788` — fresh mint (rings, CTAs)
- `--brand-accent-glow: #95E2B5` — light mint (ring highlight)
- `--brand-sunrise: #F6C177` — warm amber (activity ring, accents)
- `--brand-ember: #E07856` — terracotta (warm accent)
- `--brand-dusk: #0B2A1C` — near-black forest
- `--brand-bone: #EFEAE0` — warm off-white (body background)
- `--brand-moss: #6FA287` — desaturated sage

**Typography direction:** serif numerals for hero stats, rounded heavy for big counts, tight tracking on display, uppercase eyebrow labels with 2.2px letter-spacing.

**Effects:** aurora radial glows (screen blend) on dark hero, glass panels (white 12% + border white 22%), elevation shadows, bone paper body section overlapping/pulling up from the dark hero.

## What to Build
A single `gan-harness/index.html` — a pixel-perfect mobile dashboard mockup (390px viewport) of the VITALITY home screen.

### Required Sections (top to bottom)
1. **Dark forest hero** — layered: base forest gradient + two aurora radial glows (mint top-right, amber bottom-left, screen blend) + glass chrome bar (time+notifications) + greeting "안녕하세요, 김민준 님 👋" + date eyebrow label
2. **Vital snapshot panel** — inside hero, glass card: two SVG rings side by side — calorie ring (mint gradient, 1,420/2,000 kcal) + activity ring (sunrise gradient, 45/60 min). Below each ring: label + fraction. Between rings: macro strip (P 98g / C 165g / F 42g) with thin fill bars.
3. **Bone paper body** — pulls up with -36px top margin and rounded top corners, overlapping the hero. Background: #EFEAE0.
4. **Today's meals card** — 4 meal rows (아침/점심/저녁/간식) with emoji, name, calorie chip. Empty slots show a muted "+ 기록" row.
5. **Exercise summary card** — shows today's completed workout: 상체 루틴 · 42분 · 320 kcal. Warm accent styling.
6. **Body trend card** — current weight (72.4 kg) + 7-day sparkline SVG + weight change chip (▼ 0.8kg this week).
7. **Quick-action row** — 3 pill buttons: "+ 식단 기록" (mint), "+ 운동 기록" (warm amber), "🤖 AI 추정" (glass).
8. **Bottom tab bar** — fixed, glass blur, 5 tabs: 홈🏠 / 기록📝 / 탐색🔍 / 일기📖 / 마이페이지👤. 홈 is active (mint tint).

## Creative Mandate
- Hero depth: at minimum 3 layered elements (base gradient → aurora glow → glass panel)
- Rings: SVG `<circle>` with `stroke-dasharray` + `stroke-dashoffset`, gradient via `<defs><linearGradient>`
- Sparkline: inline SVG `<polyline>` — not a div hack
- No uniform card sizing — vary heights, use asymmetric padding for rhythm
- Pull-up overlap: body section has `margin-top: -36px; border-radius: 28px 28px 0 0`
- Must NOT look like a Bootstrap/Tailwind template
- Korean content throughout (no Lorem ipsum)
- Scrollable page, bottom tab fixed

## Realistic Placeholder Data
- User: 김민준, 29세, 목표: 체중 감량 (-5kg)
- Date: 5월 8일 목요일
- Meals: 아침 — 귀리죽 + 삶은달걀 (380 kcal), 점심 — 닭가슴살 샐러드 (520 kcal), 저녁 — 미기록, 간식 — 미기록
- Exercise: 상체 루틴 (벤치프레스 3×10, 덤벨 로우 3×12, 숄더프레스 3×10) · 42분 · 320 kcal
- Weight: 72.4 kg (7일 전: 73.2 → 73.0 → 72.9 → 72.7 → 72.6 → 72.5 → 72.4)

