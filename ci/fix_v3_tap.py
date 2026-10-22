"""Small, reproducible repair for Karya 3 source bundled in its ZIP.

The NeoCard tap callback must run synchronously. Reading the optional haptic
preference must not delay a task button or drop taps on navigation.
"""
from pathlib import Path

p=Path("lib/features/neo.dart")
code=p.read_text(encoding="utf-8")
before="""onTap:widget.onTap==null?null:()async{
          final prefs=await SharedPreferences.getInstance();
          if(prefs.getBool('haptics')??true){HapticFeedback.selectionClick();}
          if(mounted)widget.onTap?.call();
        },"""
after="""onTap:widget.onTap==null?null:(){
          widget.onTap?.call();
          SharedPreferences.getInstance().then((prefs){
            if(prefs.getBool('haptics')??true){HapticFeedback.selectionClick();}
          });
        },"""
if before in code:
    p.write_text(code.replace(before,after,1),encoding="utf-8")
    print("Fixed immediate tap response for NeoCard")
elif after in code:
    print("NeoCard callback already updated")
else:
    raise SystemExit("NeoCard tap implementation changed: inspect before patching")
