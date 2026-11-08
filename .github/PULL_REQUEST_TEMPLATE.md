**What this changes**

**Tested on**
<!-- OS, Lazarus/FPC (or Delphi) version, widgetset. Screenshots before/after if visible. -->

**Checklist** (see CONTRIBUTING.md)
- [ ] Geometry is still computed from the reference model only (deterministic)
- [ ] The scaler still works only within explicit calls; it registers no event handlers
- [ ] `TJCUIScaler` remains an `object`; its public API is compatible
- [ ] Without the new situation/feature, behaviour is identical to the current version
- [ ] Experimental features are disabled by default
- [ ] Delphi source compatibility kept (no unguarded LCL-only constructs in the core)
- [ ] License header in new files; copyright notices untouched
- [ ] CRLF line endings, comments in English
