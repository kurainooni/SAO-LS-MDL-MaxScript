fn ReadBEword fstream = (
	return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

fn ReadLEword fstream = (
	return (readshort fstream #unsigned)
)

fn ReadEword fstream = (
	if ENDIAN=='ENDIBIGE' then (return ReadBEword fstream) else (return ReadLEword fstream)
)

fn convertTo32 input16 = (
    inputAsInt = input16
    sign = bit.get inputAsInt 16
    exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and inputAsInt (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    --Ouput 32 bit integer representing a 32 bit float
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
    --Output Check   
    return bit.intasfloat outputasfloat
)

fn ReadBEHalfFloat fstream = (
	return convertTo32(ReadBEword fstream)
)

fn ReadLEHalfFloat fstream = (
	return convertTo32(ReadLEword fstream)
)

fn ReadEHalfFloat fstream = (
	return convertTo32(ReadEword fstream)
)

fn ReadBEShort fstream = (
	short = readshort fstream #unsigned
	short = bit.swapBytes short 2 1
	b = (bit.get short 16)
	for i = 17 to 32 do short = bit.set short i b
	return short
)

fn ReadLEShort fstream = (
	short = readshort fstream #unsigned
	--short = bit.swapBytes short 2 1
	b = (bit.get short 16)
	for i = 17 to 32 do short = bit.set short i b
	return short
)

fn ReadEShort fstream = (
	if ENDIAN=='ENDIBIGE' then return ReadBEShort fstream else return ReadLEShort fstream
)

fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)   

fn ReadBEword fstream = (
	return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

fn ReadLEword fstream = (
	return (readshort fstream #unsigned)
)

fn ReadBElong fstream = (
	long = readlong fstream
	long = bit.swapBytes long 1 4
	long = bit.swapBytes long 2 3
	return long
)

fn ReadLElong fstream = (
	return readlong fstream
)

fn ReadElong fstream = (
	if ENDIAN=='ENDIBIGE' then return ReadBElong fstream else return ReadLElong fstream
)

fn ReadBEfloat fstream = (
	return floatSwap2(readfloat fstream)
)

fn ReadLEfloat fstream = (
	return readfloat fstream
)

fn ReadEfloat fstream =(
	if ENDIAN=='ENDIBIGE' then return ReadBEfloat (fstream) else return ReadLEfloat (fstream)
)

fn ReadFixedString bstream fixedLen = (
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar (ReadByte bstream #unsigned)
    )
    str
)

fn ApplyNormals msh Normal_array= (
	max modify mode
	select msh
		
	--set smoothing group of all faces to 1 to get one normal per vertex
	for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
		--set normals via edit normals modifier
		select msh
		addmodifier msh (Edit_Normals ()) ui:off
		msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		EN_setNormal = msh.Edit_Normals.SetNormal
		normID = #{}
	
		--apply normals
		for v = 1 to Normal_array.count do
		(
			free normID
			EN_convertVS #{v} &normID
			for id in normID do EN_setNormal id Normal_array[v]
		)
		collapseStack msh
)

struct weight_data (
   boneids,weights
)

isBigEndian=1

rollout mdlImportRollout "MDL importer" width:168 height:184
(
	button btnOpenMDL "Open MDL" pos:[10,48] width:144 height:32
	label lbl1 "SAO:LS and DBZ BoZ importer" pos:[8,16] width:144 height:24
	label lbl5 "Original script by sleepyzay, updated by KuraiNoOni for SAO:LS" pos:[12,128] width:144 height:46
	checkbox endianType "Big Endian" pos:[12,96] width:144 height:20 checked:true
	on btnOpenMDL pressed do
	(
		OpenMDLFile()
		)
	on endianType changed state do
	(
		isBigEndian = endianType.value
	)
)

fn OpenMDLFile = (
	fname = GetOpenFileName caption:"Battle of Z|SAO Lost Song" types:"(*.mdl)|*.mdl"
	f = fopen fname "rb"   --open file in read only format
	clearlistener()
	fscale=50
	delete $*

	ENDIAN = ReadFixedString f 8
	fseek f 0x08 #seek_cur
	MDL = ReadFixedString f 3
	fseek f 0xd0 #seek_set
	-- MDL HDET --
	MDL_HDET = ReadFixedString f 8
	HDETBlockLength=ReadLElong f
	null=ReadLElong f
	TextureCount=ReadLElong f
	MTLBDataCount=ReadLElong f	--blocks 0x1a0 long
	ukw2=ReadLElong f
	BoneCount=ReadLElong f	--blocks 0x50 long
	ukw5=ReadLElong f
	fseek f 0x2c #seek_cur

Print ("Texture count is "+((TextureCount)as string))

-- MDL STHB --			name data
MDL_STHB = ReadFixedString f 8
STHBBlockLength=ReadLElong f
null=ReadLElong f
NameCount=ReadLElong f
STHBOffsetLength=ReadLElong f
TextLength=ReadLElong f
null=ReadLElong f
fseek f STHBOffsetLength #seek_cur
fseek f TextLength #seek_cur

Print ("Name count is "+((NameCount)as string))


-- MDL MTDT --			material data?
MDL_MTDT = ReadFixedString f 8
MTDTLength=ReadLElong f
fseek f 0x04 #seek_cur
fseek f MTDTLength #seek_cur

-- MDL IMGB --			dunno what this is
MDLIMGB = ReadFixedString f 8 
IMGBLength=ReadLElong f
fseek f 0x04 #seek_cur
fseek f IMGBLength #seek_cur

-- MDL MTLB --			stuff might be here
MDLMTLB = ReadFixedString f 8 
MTLBLength=ReadLElong f
fseek f 0x04 #seek_cur
fseek f MTLBLength #seek_cur

-- MDL NDEB --			bone data
MDLNDEB = ReadFixedString f 8 
NDEBLength=ReadLElong f
fseek f 0x04 #seek_cur
fseek f NDEBLength #seek_cur
-- BNArr = #()
-- for x=1 to BoneCount do (
-- 	fseek f 0x4 #seek_cur
-- 	BoneParentID = ReadLElong f + 1
-- 	fseek f 0x08 #seek_cur

-- 	m11 = ReadLEfloat f; m12 = ReadLEfloat f; m13 = ReadLEfloat f; m14 = ReadLEfloat f
-- 	m21 = ReadLEfloat f; m22 = ReadLEfloat f; m23 = ReadLEfloat f; m24 = ReadLEfloat f
-- 	m31 = ReadLEfloat f; m32 = ReadLEfloat f; m33 = ReadLEfloat f; m34 = ReadLEfloat f
-- 	m41 = ReadLEfloat f; m42 = ReadLEfloat f; m43 = ReadLEfloat f; m44 = ReadLEfloat f
-- 	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
-- 	
-- 	newBone = bonesys.createbone	\
-- 	tfm.row4	\
-- 	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 	(normalize tfm.row3)
-- 	newBone.width = 0.1
-- 	newBone.height = 0.1
-- 	newBone.wirecolor = yellow
-- 	newbone.showlinks = true
-- 	newBone.transform = inverse tfm

-- 	
-- 	pos = [m41,m42,m43]
-- 	pos = pos * tfm

-- 	newBone.pos.x += ((fscale)*pos.x)
-- 	newBone.pos.y += (-1*(fscale)*pos.z)
-- 	newBone.pos.z += ((fscale)*pos.y)	

-- 	newBone.setBoneEnable false 0
-- 	newBone.pos.controller = TCB_position ()
-- 	newBone.rotation.controller = TCB_rotation ()

-- 	append BNArr newBone
-- 	if (BoneParentID != 0) then (
-- 	newBone.parent = BNArr[BoneParentID]
-- 	newBone.transform = newBone.transform * (newBone.parent.transform)
--    )
--    
--    if BoneCount == x do (
-- 	Print "Bones Done!"
-- 	)
-- )

BackJump = ftell f
Print ("Fork @ 0x"+((bit.intAsHex(BackJump))as string))


MDL = ReadFixedString f 8
if MDL == "MDL INVB" then(
	ModelCount=0
	fseek f BackJump #seek_set
	-- MDL INVB --		
	MDLINVB = ReadFixedString f 8 
	INVBLength=ReadLElong f
	null=ReadLElong f
	ukw=ReadLElong f
	NodeCount=ReadLElong f
	ukw2=ReadLElong f
	NodeTableLength=ReadLElong f
	ukw3=ReadLElong f
	NodeDataLength=ReadLElong f
	fseek f 0x08 #seek_cur
	fseek f NodeTableLength #seek_cur
	fseek f NodeDataLength #seek_cur
	ftell
	-- MDL GEOB --
	MDLGEOB = ReadFixedString f 8 
	GEOBLength=ReadLElong f
	GEOBBlockLength=ReadLElong f
	ukw9=ReadLElong f	
	ModelCount=ReadLElong f
	fseek f 0x08 #seek_cur
	
	Print ("bone count is "+(BoneCount)as string)	
	Print ("model count is "+(ModelCount)as string)	
)

If MDL == "MDL GEOB" then(
	fseek f BackJump #seek_set
	-- MDL GEOB --
	MDLGEOB = ReadFixedString f 8 
	GEOBLength=ReadLElong f
	GEOBBlockLength=ReadLElong f
	ukw9=ReadLElong f	
	ModelCount=ReadLElong f
	fseek f 0x08 #seek_cur
	
	Print ("model count is "+(ModelCount)as string)	
)


MDLGEO=#()
GEOLength=#()
GEOBlockLength=#()
MDLSGEO=#()
SGEOLength=#()
SGEOBlockLength=#()
MDLGEOP=#()
GEOPLength=#()
VertCount=#()
VertLength=#()
FaceCount=#()
FaceLength=#()
BackJump=#()
VertSize=#()
VertSkip=#()
MeshCount=#()

for x=1 to 	ModelCount do (
	
	Print "===================================="------------------------------
	Print (("Table "+((x)as string))+("					   0x"+(bit.intAsHex(ftell f))))
	Print "===================================="------------------------------
	
	-- MDL GEO --
	MDLGEO[x] = ReadFixedString f 8 
	GEOLength[x]=ReadLElong f
	GEOBlockLength[x]=ReadLElong f
	ukw10=ReadLEshort f
	ukw11=ReadLEshort f
	MeshCount[x]=ReadLElong f
	fseek f 0x08 #seek_cur
	
	Print ("Mesh count is "+(MeshCount[x])as string)
	Print "--------------------------"
	for x=1 to MeshCount[x] do (
		Print ("Mesh # "+(x)as string)
		
		Face_array=#()
		Vert_array=#()
		UV_array=#()
		Normal_array=#()
		Weight_array=#()
		
		-- MDL SGEO --
		MDLSGEO[x] = ReadFixedString f 8 
		SGEOLength[x]=ReadLElong f
		SGEOBlockLength[x]=ReadLElong f
		ukw13=ReadLElong f
		ukw14=ReadLEshort f
		fseek f 0x0a #seek_cur
		ukw15=ReadLElong f
		ukw16=ReadLElong f
		fseek f 0x08 #seek_cur
		ukw17=ReadLEShort f
		ukw18=ReadLEShort f
		ukw19=ReadLEShort f
		ukw20=ReadLEShort f
		fseek f 0x08 #seek_cur
		ukw21=ReadLElong f
		ukw22=ReadLElong f
		ukw23=ReadLElong f
		VertSize[x]=ReadLElong f
		fseek f (SGEOBlockLength[x]-0x50) #seek_cur
		
		-- MDL GEOP --
		MDLGEOP[x] = ReadFixedString f 8 
		GEOPLength[x]=ReadLElong f
		fseek f 0x04 #seek_cur
		ukw13=ReadLElong f			--always 3
		fseek f 0x0c #seek_cur
		VertCount[x]=ReadLElong f
		ukw14=ReadLElong f			--always 30
		VertLength[x]=ReadLElong f
		null=ReadLElong f
		FaceCount[x]=ReadLElong f
		fseek f 0x04 #seek_cur			--850
		FaceLength[x]=ReadLElong f
		null=ReadLElong f
		VertSkip=(VertLength[x]-(VertCount[x]*VertSize[x]))
		FaceSkip=(FaceLength[x]-(FaceCount[x]*2))
		


		Print ("Mesh offset @ 0x"+((bit.intAsHex(ftell f))as string))
		Print ("vertex size is 0x"+((bit.intAsHex(VertSize[x]))as string))	
		Print ("vertex count is 0x"+((bit.intAsHex(VertCount[x]))as string))
		Print ("vertex length is 0x"+((bit.intAsHex(VertLength[x]))as string))
		Print ("face count is 0x"+((bit.intAsHex(FaceCount[x]))as string))
		Print ("face length is 0x"+((bit.intAsHex(FaceLength[x]))as string))
		Print ("vertex skip is 0x"+((bit.intAsHex(Vertskip))as string))
		Print ("face skip is 0x"+((bit.intAsHex(Faceskip))as string))
		Print "--------------------------"
		
		if VertSize[x] == 0x18 Do (
			for x = 1 to VertCount[x] do(
			vx=ReadLEfloat f
			vy=ReadLEfloat f
			vz=ReadLEfloat f
			fseek f 0x0c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)	
		
		if VertSize[x] == 0x1c Do (
			for x = 1 to VertCount[x] do(
			vx=ReadLEfloat f
			vy=ReadLEfloat f
			vz=ReadLEfloat f
			nx = ReadLEfloat f
			ny = ReadLEfloat f
			nz = ReadLEfloat f
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			append Normal_array [nx,-1*nz,ny]
			)
		)
		
		if VertSize[x] == 0x20 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x0c #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			fseek f 0x04 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			)
		)
		
		if VertSize[x] == 0x24 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			nx = ReadLEfloat f
			ny = ReadLEfloat f
			nz = ReadLEfloat f
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			weight1 = readbyte f#unsigned
			weight2 = readbyte f#unsigned
			weight3 = readbyte f#unsigned
			weight4 = readbyte f#unsigned
			bone1 = readbyte f#unsigned
			bone2 = readbyte f#unsigned
			bone3 = readbyte f#unsigned
			bone4 = readbyte f#unsigned
				
			w = (weight_data boneids:#() weights:#())
			maxweight = 0
			
			if(weight1 != 0) then
			   maxweight = maxweight + weight1
			if(weight2 != 0) then
			   maxweight = maxweight + weight2
			if(weight3 != 0) then
			   maxweight = maxweight + weight3
			if(weight4 != 0) then
			   maxweight = maxweight + weight4
				
			if(maxweight != 0) Do (
				
				  if(weight1 != 0) Do (
					 w1 = weight1 as float
					 append w.boneids (bone1+1)
					 append w.weights w1
				  )
				  if(weight2 != 0) Do (
					 w2 = weight2 as float
					 append w.boneids (bone2+1)
					 append w.weights w2
				  )
				  if(weight3 != 0) Do (
					 w3 = weight3 as float
					 append w.boneids (bone3+1)
					 append w.weights w3
				  )
				  if(weight4 != 0) Do (
					 w4 = weight4 as float
					 append w.boneids (bone4+1)
					 append w.weights w4
				  ) 
				  
			)  	
				
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			append Normal_array [nx,-1*nz,ny]
			append Weight_array w
			)
		)
		
		if VertSize[x] == 0x28 Do (	-- some models like to be read in beword, gotta find the difference
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x10 #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			fseek f 0x08 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*-2),((tv*-2)+1),0])
			)
		)
		
		if VertSize[x] == 0x2c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x10 #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			fseek f 0x0c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*-2),(tv*-2+1)*1.1,0])
			)
		)
		
		if VertSize[x] == 0x30 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x24 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x34 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x24 #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			)
		)
		
		if VertSize[x] == 0x38 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			nx = ReadLEfloat f
			ny = ReadLEfloat f
			nz = ReadLEfloat f	
			fseek f 0x20 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append Normal_array [nx,-1*nz,ny]
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x3c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
				
			fseek f 0x24 #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			fseek f 0x08 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*1),(tv*-1),0]*2)
				
			)
		)
		
		if VertSize[x] == 0x40 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x24 #seek_cur
			tu=ReadLEHalfFloat f
			tv=ReadLEHalfFloat f
			fseek f 0x0c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*1),(tv*-1)+1,0]*2)
			)
		)
		
		if VertSize[x] == 0x44 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x38 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x48 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x3c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x4c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadLEfloat f
			vy = ReadLEfloat f
			vz = ReadLEfloat f
			fseek f 0x40#seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		fseek f VertSkip #seek_cur
		
		for x=1 to FaceCount[x]/3 do(
			fa=ReadLEShort f +1
			fb=ReadLEShort f +1
			fc=ReadLEShort f +1
			append Face_array[fa,fb,fc]
		)
		
		fseek f FaceSkip #seek_cur		
		
		msh = mesh vertices:Vert_array faces:Face_array 
		msh.numTVerts = UV_array.count
		buildTVFaces msh
		msh.name = bit.intAsHex(VertSize[x]) as string
		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
-- 		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	
		ApplyNormals msh Normal_array



-- 		max modify mode
-- 		select msh
-- 		skinMod = skin ()
-- 		addModifier msh skinMod
-- 		for i = 1 to BNArr.count do (
-- 		   maxbone = getnodebyname BNArr[i].name
-- 		   if i != BNArr.count then
-- 			  skinOps.addBone skinMod maxbone 0
-- 		   else
-- 			  skinOps.addBone skinMod maxbone 1
-- 		)
-- 		
-- 		modPanel.setCurrentObject skinMod
-- 		
-- 		for i = 1 to Weight_array.count do (
-- 		   w = Weight_array[i]
-- 		   bi = #() --bone index array
-- 		   wv = #() --weight value array
-- 		   
-- 		   for j = 1 to w.boneids.count do (
-- 			  boneid = w.boneids[j]
-- 			  weight = w.weights[j]
-- 			  append bi boneid
-- 			  append wv weight
-- 		   )   
-- 		   
-- 			skinOps.ReplaceVertexWeights skinMod i bi wv
-- 		   
-- 		)
-- 		

	max create mode

	)
	
	if ModelCount != x do (
	Print ("Next model @ 0x"+((bit.intAsHex(ftell f))as string))
	)
	if ModelCount == x do (
	Print "Meshes Done!"
	)

)



Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
select $*
actionMan.executeAction 0 "310"  -- Tools: Zoom Extents Selected
deselect $*

gc()
fclose f
)

CreateDialog mdlImportRollout