"""

    AllEdgeCollect(NodeDict,ElemDict)

    get all element edge

"""
function AllEdgeCollect(NodeDict::Dict,ElemDict::Dict)

    # got the ElemInfor
    ElemIDArray = collect(keys(ElemDict));
    elemtotal = length(ElemIDArray);

    Edge_1_all = zeros(Int64,elemtotal,3);
    Edge_2_all = zeros(Int64,elemtotal,3);
    Edge_3_all = zeros(Int64,elemtotal,3);
    Edge_4_all = zeros(Int64,elemtotal,3);
    Edge_5_all = zeros(Int64,elemtotal,3);
    Edge_6_all = zeros(Int64,elemtotal,3);

    Threads.@threads for kelem = 1:elemtotal

        elemID = ElemIDArray[kelem];
        #=
            Tetrahedron:                          Tetrahedron10:
            
                               v
                             .
                           ,/
                          /
                       4                                     4
                     ,/|`\                                 ,/|`\
                   ,/  |  `\                             ,/  |  `\
                 ,/    '.   `\                         ,8    '.   `10
               ,/       |     `\                     ,/       9     `\
             ,/         |       `\                 ,/         |       `\
            1-----------'.--------3 --> u         1--------7--'.--------3
             `\.         |      ,/                 `\.         |      ,/
                `\.      |    ,/                      `\.      |    ,6
                   `\.   '. ,/                           `5.   '. ,/
                      `\. |/                                `\. |/
                         `2                                    `2
                            `\.
                               ` w
        =#
        node1 = ElemDict[elemID][1];
        node2 = ElemDict[elemID][2];
        node3 = ElemDict[elemID][3];
        node4 = ElemDict[elemID][4];

        Edge_1_all[kelem,:] = [elemID node1 node2];
        Edge_2_all[kelem,:] = [elemID node2 node3];
        Edge_3_all[kelem,:] = [elemID node3 node1];
        Edge_4_all[kelem,:] = [elemID node1 node4];
        Edge_5_all[kelem,:] = [elemID node2 node4];
        Edge_6_all[kelem,:] = [elemID node3 node4];

    end

    Edge_all = [Edge_1_all;Edge_2_all;Edge_3_all;Edge_4_all;Edge_5_all;Edge_6_all];

end

"""

    ConstructSparseDict(NodeDict::Dict,Edge_all::Array)

    Generate the Node in the middle of each lement edge

    ------

    TODO: accelerate the speed

"""
function ConstructSparseDict(NodeDict::Dict,Edge_all::Array)

    nodeidmax = maximum(Edge_all[:,2:3]);
    nodeidnow = nodeidmax + 1;

    nedge = size(Edge_all,1);

    NodeDictNew = deepcopy(NodeDict);
    EdgeMiddleDictSparse = spzeros(Int64,nodeidmax,nodeidmax);

    @inbounds @simd for kedge = 1:nedge
        #=
            * node A
             \
              o NEW node be abserted
               \
                * node B
        =#

        nodeA = Edge_all[kedge,2];
        nodeB = Edge_all[kedge,3];

        if (iszero(EdgeMiddleDictSparse[nodeA,nodeB])) # the edge has not been inserted middle point

            NodeDictNew[nodeidnow] = 0.5*(NodeDict[nodeA]+NodeDict[nodeB]);
            EdgeMiddleDictSparse[nodeA,nodeB] = nodeidnow;
            EdgeMiddleDictSparse[nodeB,nodeA] = nodeidnow;
            nodeidnow = nodeidnow + 1;

        end
    end
    
    return NodeDictNew,EdgeMiddleDictSparse
end

"""

    MeshRefiner(ElemDict::Dict,EdgeMiddleDictSparse::SparseMatrixCSC{Int64,Int64})


"""
function MeshRefiner(ElemDict::Dict,EdgeMiddleDictSparse::SparseMatrixCSC{Int64,Int64})

    ElemIDArrayOld = collect(keys(ElemDict));
    elemtotalold = length(ElemIDArrayOld);

    ElemDictNew = deepcopy(ElemDict);

    Threads.@threads for elemID in ElemIDArrayOld

        nodehere = zeros(Int64,10);

        nodehere[1] = ElemDict[elemID][1];
        nodehere[2] = ElemDict[elemID][2];
        nodehere[3] = ElemDict[elemID][3];
        nodehere[4] = ElemDict[elemID][4];

        nodehere[5] = EdgeMiddleDictSparse[nodehere[1],nodehere[2]];
        nodehere[6] = EdgeMiddleDictSparse[nodehere[2],nodehere[3]];
        nodehere[7] = EdgeMiddleDictSparse[nodehere[1],nodehere[3]];
        nodehere[8] = EdgeMiddleDictSparse[nodehere[1],nodehere[4]];
        nodehere[9] = EdgeMiddleDictSparse[nodehere[2],nodehere[4]];
        nodehere[10] = EdgeMiddleDictSparse[nodehere[3],nodehere[4]];

        ElemDictNew[elemID] = nodehere[[1;5;7;8]];
        ElemDictNew[elemID+elemtotalold] = nodehere[[5;2;6;9]];
        ElemDictNew[elemID+2*elemtotalold] = nodehere[[5;6;7;9]];
        ElemDictNew[elemID+3*elemtotalold] = nodehere[[7;6;3;10]];
        ElemDictNew[elemID+4*elemtotalold] = nodehere[[8;5;7;9]];
        ElemDictNew[elemID+5*elemtotalold] = nodehere[[10;9;7;6]];
        ElemDictNew[elemID+6*elemtotalold] = nodehere[[8;7;10;9]];
        ElemDictNew[elemID+7*elemtotalold] = nodehere[[8;9;10;4]];

    end

    return ElemDictNew
end

"""
"""
function ElsetDictUpdate(ElsetDict::Dict,EdgeMiddleDictSparse::SparseMatrixCSC{Int64,Int64};elemtotalold::Int64)

    ElsetDictNew = deepcopy(ElsetDict);
    for (ElsetNameHere,ElsetHere) in ElsetDict

        for elemID in ElsetHere
            append!(ElsetDictNew[ElsetNameHere],[elemID+k*elemtotalold for k=1:7]);
        end
    end
        
    return ElsetDictNew
end

"""

"""
function TetMeshDecompser(NodeDict::Dict,ElemDict::Dict,NSetDict::Dict,ElsetDict::Dict)

    # obatin all the element edges in the mesh
    Edge_all = AllEdgeCollect(NodeDict,ElemDict);

    # add middle point in the middle of the edges
    NodeDictNew,EdgeMiddleDictSparse = ConstructSparseDict(NodeDict,Edge_all);

    # update the element 
    ElemDictNew = MeshRefiner(ElemDict,EdgeMiddleDictSparse);
    
end