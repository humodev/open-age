import json
C="Gouache illustration in the style of a mid-century storybook, flat opaque color shapes, simple graphic forms, matte paper texture, limited palette."
def M(edad): return f"Portrait of a Native American Quechua man from the Peruvian Andes, {edad}: a very broad flat face, wide across the cheekbones, a strong wide jaw, a large hooked aquiline nose with a high bridge, large dark eyes with a visible double eyelid, smooth unlined copper-brown skin, rosy cheeks from the cold, dark brown lips the same tone as his skin, thick straight black hair cut short at the ears, held by a plain woven band around the head."
def W(edad): return f"Portrait of a Peruvian Andean highlander woman from a mountain village near Cusco, {edad}: a very broad round face, wide across the cheekbones, a large convex aquiline nose with a high bridge, deep-set dark eyes, smooth unlined copper-brown skin, rosy cheeks from the cold, dark brownish lips, thick straight black hair parted in the middle in two long braids that cover her ears."
O="Plain undyed brown wool clothing. Head and shoulders, the head fills the upper half of the frame, face turned slightly to the side, plain dark grey backdrop."
p=[dict(id="cara_m_late20s",nombre="Hombre · «an adult in his late twenties»",seccion="0 · Caras: fijar la edad",semilla=23,prompt=f"{C} {M('an adult in his late twenties')} {O}"),
   dict(id="cara_m_28",nombre="Hombre · «28 years old, young adult»",seccion="0 · Caras: fijar la edad",semilla=23,prompt=f"{C} {M('28 years old, a young adult')} {O}"),
   dict(id="cara_f_late20s",nombre="Mujer · «an adult in her late twenties»",seccion="0 · Caras: fijar la edad",semilla=11,prompt=f"{C} {W('an adult in her late twenties')} {O}"),
   dict(id="cara_f_28",nombre="Mujer · «28 years old, young adult»",seccion="0 · Caras: fijar la edad",semilla=11,prompt=f"{C} {W('28 years old, a young adult')} {O}")]
json.dump(p,open("piezas.json","w"),ensure_ascii=False,indent=1)
