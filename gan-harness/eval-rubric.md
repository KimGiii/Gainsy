# Design Evaluation Rubric — VITALITY Dashboard

## Scoring Weights

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Design Quality | 0.35 | Visual polish, hierarchy, color/type use, depth |
| Originality | 0.30 | Template escape, creative layout, unexpected moves |
| Craft | 0.25 | HTML/CSS quality, SVG correctness, token use |
| Functionality | 0.10 | All spec sections present, data plausible, scrollable |

## Scoring Scale (each dimension 0–10)

### Design Quality (weight 0.35)
- **9–10**: App Store "App of the Day" worthy. Every element deliberate, harmonious depth.
- **7–8**: Professional finish. Clear hierarchy, brand identity strong, spacing rhythmic.
- **5–6**: Looks okay but generic.
- **3–4**: Barely above default Bootstrap.
- **1–2**: Inconsistent, cluttered, or unfinished.

Checklist:
- [ ] Hero has genuine layered depth (≥3 layers: gradient + aurora glows + glass)?
- [ ] Typography scale shows clear contrast (hero numeral vs body vs caption)?
- [ ] Bone paper body overlaps dark hero with pull-up card effect?
- [ ] Rings use actual SVG gradient fills (not CSS border tricks)?
- [ ] Spacing varies — asymmetric rhythm, not identical padding everywhere?
- [ ] Color is semantic — mint for progress/positive, amber for activity, bone for calm?
- [ ] Empty meal slots have designed empty states (not just blank)?

### Originality (weight 0.30)
- **9–10**: "I've never seen a health dashboard look like this." Unexpected creative leaps.
- **7–8**: Familiar patterns twisted intelligently.
- **5–6**: Some fresh element but mostly predictable.
- **3–4**: Standard card-grid health dashboard.
- **1–2**: Full template.

Checklist:
- [ ] Avoids blue rings (Apple Watch cliché)?
- [ ] Hero aurora effect creates genuine atmosphere?
- [ ] Macro strip is a designed component, not just text?
- [ ] Sparkline is real SVG, not a fake bar?
- [ ] Quick-action row has personality (not just 3 identical buttons)?
- [ ] Tab bar has a designed active state (not just an underline)?

### Craft (weight 0.25)
- **9–10**: CSS custom properties for all tokens, semantic HTML, SVGs correct, no magic numbers.
- **7–8**: Clean code, consistent token use, only minor shortcuts.
- **5–6**: Works but has hardcoded values or repetition.
- **3–4**: Lots of magic numbers, inline styles everywhere.
- **1–2**: Broken layout or incorrect SVG math.

Checklist:
- [ ] CSS variables defined for all brand colors?
- [ ] SVG ring math correct (circumference = 2π×r, dashoffset = circumference × (1 - progress))?
- [ ] Sparkline polyline points match the data array?
- [ ] Mobile viewport meta tag present?
- [ ] Bottom tab bar is fixed (not static)?
- [ ] No Lorem ipsum — all Korean content?

### Functionality (weight 0.10)
- [ ] All 8 spec sections present?
- [ ] Page scrolls (body content taller than viewport)?
- [ ] Bottom tab stays fixed while scrolling?
- [ ] Data is realistic (calorie math adds up roughly)?

## Final Score Formula
```
Score = (DesignQuality × 0.35) + (Originality × 0.30) + (Craft × 0.25) + (Functionality × 0.10)
```
**Pass threshold: 7.5**

## Evaluator Instructions
1. Open `gan-harness/index.html` via Playwright screenshot — evaluate what you actually see
2. Read the HTML/CSS source to check Craft dimension
3. Ask yourself: "Would this win a design award at a developer conference?"
4. Write structured feedback to `gan-harness/feedback-{N}.md` with specific line-level suggestions
5. Never write "make it better" — write "change X on line Y to Z because..."

