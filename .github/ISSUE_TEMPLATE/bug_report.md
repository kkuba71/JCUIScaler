---
name: Bug report
about: Something does not scale or behave as documented
labels: bug
---

**What happens**
<!-- A clear description of the problem. Screenshots before/after resizing help a lot. -->

**What you expected**

**How to reproduce**
1.
2.

**Environment**
- OS and version:
- Lazarus / FPC version (or Delphi version):
- Widgetset (Win32/Win64, Cocoa, GTK2, Qt…):
- Integration: TJCScaler component / manual (three calls)
- Screen scaling / DPI and the form's DesignTimePPI:

**Checked recommendations** (Specification, section 13.1)
- [ ] Controls use the default `Anchors = [akLeft, akTop]`
- [ ] TListView in vsReport uses `ScrollBars = ssVertical`
