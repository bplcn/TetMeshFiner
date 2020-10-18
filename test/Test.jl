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

# write .inp file
InpName = "test/Model30001output.inp";
fID = open(InpName,"w");

# *Heading
println(fID,"*Heading");

# *Part
println(fID,"*Part,name=Part-1");

    # node
    println(fID,"*Node");
    for nodeID in sort(collect(keys(NodeDictNew)))
        println(fID,"$(nodeID), $(NodeDictNew[nodeID][1]), $(NodeDictNew[nodeID][2]), $(NodeDictNew[nodeID][3])");
    end

    # element
    println(fID,"*ELEMENT, TYPE=C3D4")
    for elemID in keys(ElemDictNew)
        println(fID,"$(elemID), $(ElemDictNew[elemID][1]), $(ElemDictNew[elemID][2]), $(ElemDictNew[elemID][3]), $(ElemDictNew[elemID][4])");
    end

    # Elset
    for (SetName,SetMembers) in ElsetDictNew
        println(fID,"*Elset, Elset="*SetName);
        nnode = length(SetMembers);
        nline = Int64.((length(SetMembers)+10-mod(length(SetMembers),10))/10);
        for kline = 1:(nline-1)
            strtemp = "";
            for kmem = 1:10
                strtemp = strtemp*"$(SetMembers[(kline-1)*10+kmem]),";
            end
            println(fID,strtemp);
        end

        strtemp = "";
        for kmem = 1:mod(length(SetMembers),10)
            strtemp = strtemp*"$(SetMembers[(nline-1)*10+kmem]),";
        end
        if ~isempty(strtemp)
            println(fID,strtemp);
        end

    end

    # Fiber Set
    println(fID,"*Elset, Elset=FIBER");
    for kfiber = 1:30
        println(fID,"FIBER$(kfiber)");
    end

    # Solid Section
    println(fID,"*Solid Section, elset=FIBER, material=FIBER");
    println(fID,",");
    println(fID,"*Solid Section, elset=MATRIX, material=MATRIX");
    println(fID,",");

    

println(fID,"*End Part")

close(fID)