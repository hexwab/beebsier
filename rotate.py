import math
import copy

test = 0
test2 = 0
if test:
    import pygame
    pygame.init()
    SCREEN_WIDTH = 800
    SCREEN_HEIGHT = 800
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    clock = pygame.time.Clock()
    from pygame.locals import (
        K_UP,
        K_DOWN,
        K_LEFT,
        K_RIGHT,
        K_ESCAPE,
        KEYDOWN,
        QUIT,
    )


def rotate(nodes,t2,ax1,ax2):
    for node in nodes:
        x      = node[ax1]
        y      = node[ax2]
        d      = math.hypot(y, x)
        theta  = t2 + math.atan2(y, x)
        #print ("x=%f y=%f d=%f" % (x,y,d))
        #print ("theta before %f" % theta)
        node[ax1] = d * math.cos(theta)
        node[ax2] = d * math.sin(theta)
        #print ("after: x=%f y=%f" % (node[ax1],node[ax2]))
        
        #print ("theta after %f" % math.atan2(node[ax2],node[ax1]))

n = 64
out = []
xscale = 23
xoff = 40
yscale = 23
yoff = 40
r1 = 0.24 #!
inc = 0.1
j = 0.0

if test2: n=6
for i in range(int(1e10) if test else n):
    nodes = [[1,1,1], [1,-1,-1], [-1,1,-1], [-1,-1,1]]
    rotate(nodes, math.pi/4, 1, 2)
    rotate(nodes, math.atan2(-1,-math.sqrt(2)), 0, 1)
    rotate(nodes, (i+j)*2*math.pi/n, 0, 2)
    rotate(nodes, math.pi, 1, 2)
    rotate(nodes, r1, 1, 2)

    #rotate(nodes, r2, 0, 1)
    #rotate(nodes, math.pi, 0, 1)
    #rotate(nodes, .2, 1, 2)
    if test:
        screen.fill((0,0,0))
        for event in pygame.event.get():
            if event.type == KEYDOWN:
                if event.key == K_LEFT:
                    r1 -= inc
                    print(r1)
                if event.key == K_RIGHT:
                    r1 += inc
                    print(r1)
                if event.key == K_UP:
                    r2 += inc
                    print(r2)
                if event.key == K_DOWN:
                    r2 -= inc
                    print(r2)

        for p in range(4):
            for q in range(p,4):
                pygame.draw.line(screen, (255,255,255),
                                 (nodes[p][0]*200+300,nodes[p][1]*200+300),
                                 (nodes[q][0]*200+300,nodes[q][1]*200+300))
                
        pygame.display.flip()
        clock.tick(30)
        
    elif test2:
        print(i,nodes)
    else:
        out.append(copy.deepcopy(nodes))

if test2:
    exit(0)
# hack
#for frame in out:
#    frame[3][0] = out[0][3][0]
#    frame[3][1] = out[0][3][1]

xmin = ymin = 1e9
xmax = ymax = -1e9
for v in range(4):
    print(".xcoordtab%d " % v)
    for frame in out:
        x = frame[v][0] * xscale + xoff
        if xmax < x: xmax = x
        if xmin > x: xmin = x
        if v<3: # hack
            print ("equb %d" % x)

for v in range(4):
    print(".ycoordtab%d " % v)
    for frame in out:
        y = frame[v][1] * yscale + yoff
        if ymax < y: ymax = y
        if ymin > y: ymin = y
        if v<3: # hack
            print ("equb %d" % y)

print ("xcoord3=%d" % (out[0][3][0] * xscale + yoff))
print ("ycoord3=%d" % (out[0][3][1] * yscale + yoff))

print (";xmin=%f xmax=%f ymin=%f ymax=%f" % (xmin,xmax,ymin,ymax))
