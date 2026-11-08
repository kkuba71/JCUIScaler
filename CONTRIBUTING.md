# Contributing to JCUIScaler

*Polska wersja: [CONTRIBUTING.pl.md](CONTRIBUTING.pl.md)*

Thank you for your interest. Contributions are welcome — bug reports, test reports from your platform, fixes and new features. JCUIScaler is used in production applications, so changes must respect a small set of architecture rules. Please read them before writing code: it saves both of us from a pull request that cannot be merged.

## Where help is most wanted

Look for issues labelled **help wanted**:

- **Monitor change with a different DPI (LCL)** — moving a `Form.Scaled` window between monitors with different scaling.
- **DPI change in Delphi/VCL** — the same problem in VCL (`OnBeforeMonitorDpiChanged` / `OnAfterMonitorDpiChanged`).
- **Font scaling** — labelled **experimental** as well (see the rules for experimental features below).

Each of these issues describes what we already know and what the solution must preserve.

## Architecture rules (non-negotiable)

1. **Deterministic reference model.** Every geometry computation starts from the model captured on the first `ScalerOnShow` — never from the current, already scaled state. Repeated resizing must return to exactly the same pixels.
2. **Explicit calls only.** The scaler works only inside explicit calls made by the application or by the integration layer (`ScalerInit`, `ScalerOnShow`, `ScalerOnResize`, `RestoreInitialScale`). It must **not register event handlers** on the form or on controls by itself. Adding a new explicit call (for example for a monitor change) is acceptable.
3. **`object`, not `class`.** `TJCUIScaler` stays an `object` type. Its lifetime must not depend on the form's controls.
4. **No DPI dependency in the core.** The core scales from window geometry only; it does not read the system DPI.
5. **Integration layer vs. core.** The `TJCScaler` component may hook form events, but only to call the core's public methods. New functionality should go into the integration layer (events, virtual methods) where possible, not into the core.
6. **Configuration before code.** Problems caused by LCL or widgetset behaviour are solved first by a configuration recommendation or documentation (see Specification, section 13.1), not by changing the core.
7. **Stable API.** The name and public API of `TJCUIScaler` must stay compatible — the manual integration is used in production applications.

Changes to the core are possible after 1.0, but only within these rules.

### Changes touching the OnShow/OnResize sequence

The event sequence is the most sensitive area. Any change that touches it (this includes the monitor-change work) must keep the behaviour **identical to 1.0 when the new situation does not occur** — e.g. without a monitor change, everything works exactly as before.

### Experimental features (e.g. font scaling)

- **Disabled by default**, enabled explicitly (e.g. by a property).
- **When disabled, behaviour is identical to the current version** — bit for bit.
- **Determinism applies in the experimental mode too.**
- Describe the behaviour on every platform you tested.

## Code conventions

- Comments in English. CRLF line endings (enforced by `.gitattributes`).
- **Delphi source compatibility:** keep `{$IFDEF FPC}` blocks minimal; do not introduce LCL-only constructs in the core without a guard. The component and the packages are Lazarus-only.
- Every new source file carries the license header used in the existing files. **Do not remove copyright notices or the original author's name** from source files.

## Testing

- The demo and both packages must build — **CI checks this automatically** on every push and pull request (Linux/GTK2).
- In your pull request, describe what you tested and on which platform (OS, Lazarus/FPC version, widgetset), and attach screenshots **before and after** where the change is visible.
- Before merging a change to the core, the maintainer runs a pixel-exact A/B comparison of the demo (before vs. after). You do not need to replicate that setup.

## Documentation

The **Technical Specification** (`docs/pl`, `docs/en`) is the maintained document. If your change affects behaviour, configuration or the API, describe it in the pull request; the maintainer updates the specification (the Polish version is the source document). The documents in `docs/*/Additional` record the development up to 1.0 and are not updated on an ongoing basis.

## Issues and pull requests

- Use the issue templates (bug report, platform test report, feature proposal). English or Polish is fine.
- Keep pull requests focused: one topic per pull request.
- The pull request template contains a short checklist of the rules above.

## License

By submitting a contribution you agree that it is distributed under the project's license (GNU Library General Public License version 2 with the static linking exception — see `LICENSE`).
