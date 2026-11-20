# Reemplazo de torchmcubes (no compila sin el toolkit de CUDA): usa PyMCubes en CPU.
# torchmcubes devuelve los vértices en orden (z, y, x); PyMCubes en (x, y, z): se invierten
# (y se da vuelta el orden de las caras para conservar la orientación).
import mcubes, numpy as np, torch
def marching_cubes(vol, thresh):
    v, f = mcubes.marching_cubes(vol.detach().float().cpu().numpy(), float(thresh))
    v = np.ascontiguousarray(v[:, ::-1]); f = np.ascontiguousarray(f[:, ::-1])
    return torch.from_numpy(v.astype(np.float32)).to(vol.device), torch.from_numpy(f.astype(np.int64)).to(vol.device)
