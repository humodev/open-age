"""Extrae de KayKit Character Animations (CC0) solo las animaciones que usa el juego.

Arma un único glTF con el esqueleto Rig_Medium, el maniquí de referencia y las animaciones
elegidas, para no subir el paquete entero (proceso/27-animaciones).

    blender -b --python tools/kaykit_extraer.py -- <carpeta KayKit_Character_Animations_1.1> <salida.glb>

La lista de animaciones está acá abajo (ANIMS); si se agregan, se vuelve a correr.
"""
import os
import sys

import bpy

ANIMS = {
    "General": ["Idle_A", "Interact", "PickUp", "Death_A", "Death_B", "Hit_A", "Hit_B", "Throw"],
    "MovementBasic": ["Walking_A", "Running_A"],
    "Tools": ["Chopping", "Pickaxing", "Digging", "Working_A", "Hammering"],
    # Paso 2 (soldados, proceso/27-animaciones/02-soldados.md): golpe con una y con dos manos,
    # estocada, dos armas, bloqueo y guardia.
    "CombatMelee": ["Melee_1H_Attack_Chop", "Melee_1H_Attack_Stab", "Melee_2H_Attack_Chop", "Melee_2H_Attack_Stab",
                    "Melee_2H_Idle", "Melee_Dualwield_Attack_Slice", "Melee_Block_Hit", "Melee_Blocking"],
    # Arco (tensar y soltar) y arma de fuego de dos manos (disparar y recargar). La honda no está
    # en KayKit: usa Throw.
    "CombatRanged": ["Ranged_Bow_Draw", "Ranged_Bow_Release", "Ranged_Bow_Idle", "Ranged_2H_Shoot", "Ranged_2H_Reload", "Ranged_2H_Aiming"],
}

argv = sys.argv[sys.argv.index("--") + 1:]
src, out = argv[0], argv[1]
rig_dir = os.path.join(src, "Animations", "gltf", "Rig_Medium")

bpy.ops.wm.read_factory_settings(use_empty=True)

# 1. La base: el esqueleto completo de las animaciones (con los huesos handslot.l/r de las
# herramientas) y el maniquí con su piel. Sin piel, Godot no arma un Skeleton3D.
bpy.ops.import_scene.gltf(filepath=os.path.join(rig_dir, "Rig_Medium_General.glb"))
arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
keep_objs = set(bpy.context.scene.objects)
wanted = [a for a in bpy.data.actions if a.name.split("|")[-1] in ANIMS["General"]]
for act in wanted:
    act.name = act.name.split("|")[-1]
    act.use_fake_user = True

# 2. Las demás animaciones: cada archivo trae su propio esqueleto; se queda solo con las acciones.
for fname, names in ANIMS.items():
    if fname == "General":
        continue
    before = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=os.path.join(rig_dir, "Rig_Medium_%s.glb" % fname))
    for act in set(bpy.data.actions) - before:
        base = act.name.split("|")[-1]
        if base in names:
            act.name = base
            act.use_fake_user = True
            wanted.append(act)
    for o in list(bpy.context.scene.objects):
        if o not in keep_objs:
            bpy.data.objects.remove(o, do_unlink=True)

for act in list(bpy.data.actions):
    if act not in wanted:
        bpy.data.actions.remove(act)

# Cada acción, a una pista del NLA para que el exportador las saque todas por nombre.
ad = arm.animation_data or arm.animation_data_create()
for tr in list(ad.nla_tracks):
    ad.nla_tracks.remove(tr)
for act in wanted:
    tr = ad.nla_tracks.new()
    tr.name = act.name
    st = tr.strips.new(act.name, 0, act)
    if hasattr(st, "action_slot") and len(act.slots) > 0:
        st.action_slot = act.slots[0]
ad.action = None

print("animaciones:", sorted(a.name for a in wanted))
bpy.ops.export_scene.gltf(
    filepath=out,
    export_format="GLB",
    export_animations=True,
    export_animation_mode="NLA_TRACKS",
    export_force_sampling=True,
    export_frame_step=1,
    export_optimize_animation_size=True,
    export_def_bones=False,
    export_apply=False,
)
print("escrito:", out, os.path.getsize(out) // 1024, "KB")
