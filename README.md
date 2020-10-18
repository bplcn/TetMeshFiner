# TetMeshFiner
A simple package that finer tetrahedron finite element mesh.

## How it work 
The module will decompose all the tetrahedron elements into 8 small tetrahedron element. The notation can be seen in Fig.1.

![Finer](figs\Finer.jpg)
Fig.1. The present decomposing scheme.


## Usage
```julia
using TetMeshFiner 
using AbaAccess 
##

@time NodeDict,ElemDict,NSetDict,ElsetDict=MeshObtain("test/Model30001.inp");
ElemIDArrayOld = collect(keys(ElemDict));
elemtotalold = length(ElemIDArrayOld);


# obatin all the element edges in the mesh
@time Edge_all = AllEdgeCollect(NodeDict,ElemDict);

# add middle point in the middle of the edges
@time NodeDictNew,EdgeMiddleDictSparse = ConstructSparseDict(NodeDict,Edge_all);

# update the element 
@time ElemDictNew = MeshRefiner(ElemDict,EdgeMiddleDictSparse);

@time ElsetDictNew = ElsetDictUpdate(ElsetDict,EdgeMiddleDictSparse,elemtotalold=elemtotalold);
```
