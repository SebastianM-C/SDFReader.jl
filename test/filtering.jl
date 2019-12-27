using .SDF
using Test
file_name = "0002.sdf"
bloks = fetch_blocks(file_name)
f = open(file_name)
ar1=read!(f, bloks[4])
ar4, idx4=Main.SDF.read2(f, bloks[4]; req_pts=((1, 3), (2, 6), (3, 6)), fn=x->x>0)
close(f)

@test ar4 == ar1[idx4]
