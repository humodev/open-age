# Vista rápida sin GPU de GLB crudos (proceso/43): pinta triángulos ordenados por profundidad.
# uso: gen3d/venv_hy/bin/python tools/gen3d_vista.py salida.jpg a.glb b.glb ... (filas: frente, costado, 3/4)
import sys, numpy as np, trimesh
from PIL import Image, ImageDraw
out=sys.argv[1]; files=sys.argv[2:]
S=320; tiles=[]
for f in files:
    m=trimesh.load(f, force='mesh')
    if len(m.faces)>20000:
        import pymeshlab
        ms=pymeshlab.MeshSet(); ms.add_mesh(pymeshlab.Mesh(m.vertices,m.faces))
        ms.meshing_decimation_quadric_edge_collapse(targetfacenum=20000)
        mm=ms.current_mesh(); m=trimesh.Trimesh(mm.vertex_matrix(),mm.face_matrix())
    v=m.vertices-m.bounds.mean(0); v/= (m.extents.max())
    row=[]
    for yaw in [0, 90, 35]:
        a=np.radians(yaw); R=np.array([[np.cos(a),0,np.sin(a)],[0,1,0],[-np.sin(a),0,np.cos(a)]])
        b=np.radians(15); Rx=np.array([[1,0,0],[0,np.cos(b),-np.sin(b)],[0,np.sin(b),np.cos(b)]])
        w=v@R.T@Rx.T; tri=w[m.faces]
        n=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]); n/=np.linalg.norm(n,axis=1,keepdims=True)+1e-9
        sh=np.clip(0.25+0.75*np.abs(n@np.array([0.3,0.5,0.8])),0,1)
        order=np.argsort(tri[:,:,2].mean(1))
        im=Image.new('RGB',(S,S),(235,232,225)); d=ImageDraw.Draw(im)
        for i in order:
            p=[(S/2+x*S*0.9, S/2-y*S*0.9) for x,y,_ in tri[i]]
            c=int(200*sh[i]); d.polygon(p, fill=(c,int(c*0.95),int(c*0.88)))
        row.append(im)
    tiles.append(row)
o=Image.new('RGB',(3*S,len(tiles)*S))
for j,r in enumerate(tiles):
    for i,im in enumerate(r): o.paste(im,(i*S,j*S))
o.save(out, quality=85)
