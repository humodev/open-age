# Recursos gratuitos para el arte (2026-11-16)

> El autor: "Continuemos mejorando lo visual ahora que tenemos una mejor escala. ¿Podemos buscar modelos, arte y animaciones de este tipo de juegos que sean gratuitos? Aunque no sean CC0 y tengamos que dar crédito, que le den un mejor realismo."

## Licencias verificadas

Licencias leídas en la página de cada sitio el 2026-11-16.

| Recurso | Qué trae | Licencia | Para qué nos sirve |
|---|---|---|---|
| [KayKit · Character Animations](https://kaylousberg.itch.io/kaykit-character-animations) | 161 animaciones humanoides (moverse, combate cuerpo a cuerpo y a distancia, herramientas, "simulación"), en FBX y glTF; andan en Godot con retargeting | CC0, gratis (la fuente en Blender es paga) | **Animaciones de aldeanos y soldados:** caminar, talar, picar, cosechar, pegar, disparar y morir. Retargeteadas a los modelos de Meshy |
| [Quaternius · Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | Más de 120 animaciones para un esqueleto universal, compatible con Godot y Mixamo; 45 gratis, el resto por 9,99 USD | CC0 | Segunda fuente de animaciones, y la mejor documentada para retargeting en Godot |
| [Quaternius · Ultimate Animated Animal Pack](https://quaternius.com/packs/ultimateanimatedanimals.html) | 12 animales con más de 12 animaciones cada uno (caminar, galopar, atacar, morir), en FBX, glTF y Blend | CC0, gratis | **Animaciones de animales** (caminar, pastar, morir) para los rebaños y la caza; las siluetas propias (llama, búfalo, tapir) se pueden rigear con esos esqueletos |
| [ambientCG](https://ambientcg.com) | Materiales PBR (tierra, pasto, piedra, adobe, paja, madera), HDRI y algunos modelos | CC0, gratis | **Suelo y materiales:** texturas PBR para el terreno y para los edificios procedurales (pirca, adobe, paja, teja) |
| [Poly Haven · modelos](https://polyhaven.com/models) | Modelos realistas: naturaleza (árboles, plantas, rocas) y utilería (cestos, vasijas, herramientas) | La página no lo dice; Poly Haven publica todo en CC0 [verificar en cada ficha] | **Naturaleza y utilería:** árboles, rocas y objetos para darle realismo al paisaje y a los almacenes |
| [KayKit · Forest Nature Pack](https://kaylousberg.itch.io/) | Árboles, rocas y plantas low poly | La página no lo dice; KayKit suele publicar en CC0 [verificar] | Naturaleza estilizada, si preferimos low poly a realista |

## Sin verificar

No se pudo abrir la página (403):
- [Smithsonian 3D](https://3d.si.edu): escaneos de piezas de museo en acceso abierto (CC0) [verificar].
- [Poly Pizza](https://poly.pizza): buscador de modelos low poly CC0 y CC-BY.
- [Mixamo](https://www.mixamo.com): animaciones gratis con cuenta de Adobe; se pueden usar en juegos, pero no redistribuir los archivos sueltos [verificar].
- [Sketchfab](https://sketchfab.com): hay escaneos de patrimonio (andino, etíope, siamés) con CC-BY; hay que revisar la licencia de cada modelo.

## Criterio

- **Lo genérico:** animaciones, naturaleza, materiales y utilería, de estos paquetes.
- **Lo que hace a cada pueblo:** edificios, tropas, hitos y vestimenta siguen siendo propios (Meshy y procedural), con la identidad de `docs/07` y las notas de fuentes.
- **Nada de recursos que caricaturicen culturas**, aunque sean gratis.
- **Créditos:** todo CC-BY va a `assets/CREDITOS.md` con autor, enlace y licencia. Lo CC0 se anota igual, por prolijidad.

## Plan propuesto

1. **Animaciones** (el pendiente de C-65): rigear los modelos de Meshy (aldeanos de los seis pueblos y tropas), retargetear KayKit o Quaternius en Godot y reemplazar la animación de maqueta. Con eso se ajusta el paso a la velocidad.
2. **Materiales PBR** de ambientCG para el suelo y los edificios procedurales.
3. **Árboles y rocas** de Poly Haven o KayKit, con la escala nueva (árbol de 4 personas de alto).
4. **Animales animados** de Quaternius para los rebaños y la caza.
