fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
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

fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
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

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
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

fname = GetOpenFileName caption:"Battle of Z" types:"(*.mdl)|*.mdl"
f = fopen fname "rb"   --open file in read only format
clearlistener()
fscale=50
delete $*

ENDIBIGE = ReadFixedString f 8
fseek f 0x08 #seek_cur
MDL = ReadFixedString f 3
fseek f 0xd0 #seek_set
-- MDL HDET --
MDL_HDET = ReadFixedString f 8
HDETBlockLength=ReadBElong f
null=ReadBElong f
TextureCount=ReadBElong f
MTLBDataCount=ReadBElong f	--blocks 0x1a0 long
ukw2=ReadBElong f
BoneCount=ReadBElong f	--blocks 0x50 long
ukw5=ReadBElong f
fseek f 0x2c #seek_cur

Print ("Texture count is "+((TextureCount)as string))

-- MDL STHB --			name data
MDL_STHB = ReadFixedString f 8
STHBBlockLength=ReadBElong f
null=ReadBElong f
NameCount=ReadBElong f
STHBOffsetLength=ReadBElong f
TextLength=ReadBElong f
null=ReadBElong f
fseek f STHBOffsetLength #seek_cur
fseek f TextLength #seek_cur

Print ("Name count is "+((NameCount)as string))


-- MDL MTDT --			material data?
MDL_MTDT = ReadFixedString f 8
MTDTLength=ReadBElong f
fseek f 0x04 #seek_cur
fseek f MTDTLength #seek_cur

-- MDL IMGB --			dunno what this is
MDLIMGB = ReadFixedString f 8 
IMGBLength=ReadBElong f
fseek f 0x04 #seek_cur
fseek f IMGBLength #seek_cur

-- MDL MTLB --			stuff might be here
MDLMTLB = ReadFixedString f 8 
MTLBLength=ReadBElong f
fseek f 0x04 #seek_cur
fseek f MTLBLength #seek_cur

-- MDL NDEB --			bone data
MDLNDEB = ReadFixedString f 8 
NDEBLength=ReadBElong f
fseek f 0x04 #seek_cur
fseek f NDEBLength #seek_cur
-- BNArr = #()
-- for x=1 to BoneCount do (
-- 	fseek f 0x4 #seek_cur
-- 	BoneParentID = ReadBElong f + 1
-- 	fseek f 0x08 #seek_cur

-- 	m11 = ReadBEfloat f; m12 = ReadBEfloat f; m13 = ReadBEfloat f; m14 = ReadBEfloat f
-- 	m21 = ReadBEfloat f; m22 = ReadBEfloat f; m23 = ReadBEfloat f; m24 = ReadBEfloat f
-- 	m31 = ReadBEfloat f; m32 = ReadBEfloat f; m33 = ReadBEfloat f; m34 = ReadBEfloat f
-- 	m41 = ReadBEfloat f; m42 = ReadBEfloat f; m43 = ReadBEfloat f; m44 = ReadBEfloat f
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
	fseek f BackJump #seek_set
	-- MDL INVB --		
	MDLINVB = ReadFixedString f 8 
	INVBLength=ReadBElong f
	null=ReadBElong f
	ukw=ReadBElong f
	NodeCount=ReadBElong f
	ukw2=ReadBElong f
	NodeTableLength=ReadBElong f
	ukw3=ReadBElong f
	NodeDataLength=ReadBElong f
	fseek f 0x08 #seek_cur
	fseek f NodeTableLength #seek_cur
	fseek f NodeDataLength #seek_cur
	
	-- MDL GEOB --
	MDLGEOB = ReadFixedString f 8 
	GEOBLength=ReadBElong f
	GEOBBlockLength=ReadBElong f
	ukw9=ReadBElong f	
	ModelCount=ReadBElong f
	fseek f 0x08 #seek_cur
	
	Print ("bone count is "+(BoneCount)as string)	
	Print ("model count is "+(ModelCount)as string)	
)

If MDL == "MDL GEOB" then(
	fseek f BackJump #seek_set
	-- MDL GEOB --
	MDLGEOB = ReadFixedString f 8 
	GEOBLength=ReadBElong f
	GEOBBlockLength=ReadBElong f
	ukw9=ReadBElong f	
	ModelCount=ReadBElong f
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
	GEOLength[x]=ReadBElong f
	GEOBlockLength[x]=ReadBElong f
	ukw10=ReadBEshort f
	ukw11=ReadBEshort f
	MeshCount[x]=ReadBElong f
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
		SGEOLength[x]=ReadBElong f
		SGEOBlockLength[x]=ReadBElong f
		ukw13=ReadBElong f
		ukw14=ReadBEshort f
		fseek f 0x0a #seek_cur
		ukw15=ReadBElong f
		ukw16=ReadBElong f
		fseek f 0x08 #seek_cur
		ukw17=ReadBEShort f
		ukw18=ReadBEShort f
		ukw19=ReadBEShort f
		ukw20=ReadBEShort f
		fseek f 0x08 #seek_cur
		ukw21=ReadBElong f
		ukw22=ReadBElong f
		ukw23=ReadBElong f
		VertSize[x]=ReadBElong f
		fseek f (SGEOBlockLength[x]-0x50) #seek_cur
		
		-- MDL GEOP --
		MDLGEOP[x] = ReadFixedString f 8 
		GEOPLength[x]=ReadBElong f
		fseek f 0x04 #seek_cur
		ukw13=ReadBElong f			--always 3
		fseek f 0x0c #seek_cur
		VertCount[x]=ReadBElong f
		ukw14=ReadBElong f			--always 30
		VertLength[x]=ReadBElong f
		null=ReadBElong f
		FaceCount[x]=ReadBElong f
		fseek f 0x04 #seek_cur			--850
		FaceLength[x]=ReadBElong f
		null=ReadBElong f
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
			vx=ReadBEfloat f
			vy=ReadBEfloat f
			vz=ReadBEfloat f
			fseek f 0x0c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)	
		
		if VertSize[x] == 0x1c Do (
			for x = 1 to VertCount[x] do(
			vx=ReadBEfloat f
			vy=ReadBEfloat f
			vz=ReadBEfloat f
			nx = ReadBEfloat f
			ny = ReadBEfloat f
			nz = ReadBEfloat f
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			append Normal_array [nx,-1*nz,ny]
			)
		)
		
		if VertSize[x] == 0x20 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x0c #seek_cur
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
			fseek f 0x04 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[tu,tv,0]
			)
		)
		
		if VertSize[x] == 0x24 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			nx = ReadBEfloat f
			ny = ReadBEfloat f
			nz = ReadBEfloat f
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
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
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x10 #seek_cur
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
			fseek f 0x08 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*-1),tv,0]*2)
			)
		)
		
		if VertSize[x] == 0x2c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x20 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x30 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x24 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x34 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x24 #seek_cur
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([tu,(tv*-1),0]*2)
			)
		)
		
		if VertSize[x] == 0x38 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			nx = ReadBEfloat f
			ny = ReadBEfloat f
			nz = ReadBEfloat f	
			fseek f 0x20 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append Normal_array [nx,-1*nz,ny]
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x3c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
				
			fseek f 0x24 #seek_cur
			tu=ReadBEHalfFloat f
			tv=ReadBEHalfFloat f
			fseek f 0x08 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array([(tu*1),(tv*-1),0]*2)
				
			)
		)
		
		if VertSize[x] == 0x40 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x34 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x44 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x38 #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x48 Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x3c #seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		if VertSize[x] == 0x4c Do (
			for x = 1 to VertCount[x] do(
			vx = ReadBEfloat f
			vy = ReadBEfloat f
			vz = ReadBEfloat f
			fseek f 0x40#seek_cur
			append Vert_array([vx,-1*vz,vy]*fscale)
			append UV_array[0,0,0]
			)
		)
		
		fseek f VertSkip #seek_cur
		
		for x=1 to FaceCount[x]/3 do(
			fa=ReadBEShort f +1
			fb=ReadBEShort f +1
			fc=ReadBEShort f +1
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
