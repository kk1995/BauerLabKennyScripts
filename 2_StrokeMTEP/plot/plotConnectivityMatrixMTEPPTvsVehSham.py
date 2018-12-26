import h5py
import numpy as np
from pathlib import Path
from mpl_toolkits.axes_grid1 import make_axes_locatable
import matplotlib.pyplot as plt
import matlab.engine

def getTickLabels():
    strs = []
    strs.append("Olf")
    strs.append("Fr")
    strs.append("Cing")
    strs.append("M2")
    strs.append("M1")
    strs.append("SS")
    strs.append("RS")
    strs.append("P")
    strs.append("V2m")
    strs.append("V1")
    strs.append("V2l")
    strs.append("Aud")
    for i in range(0,len(strs)):
        strs.append(strs[i])
    print(strs)
    return strs

def imagesc(ax,data,clim,boundary,tickLoc):
    im = ax.imshow(data, interpolation='none',
                   cmap='jet')
    labels = getTickLabels()
    plt.sca(ax)
    plt.yticks(tickLoc, labels, color='black', fontsize = 8)
    plt.xticks(tickLoc, labels, color='black', rotation=90, fontsize = 8)
    #plt.gca().set_xticks(tickLoc)
    #plt.gca().set_yticks(tickLoc)
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    plt.colorbar(im, cax=cax)
    im.set_clim(clim[0],clim[1])
    yLim = [0, data.shape[0]-1]
    for x in boundary:
        ax.plot([x, x],yLim, linewidth=1, color='black')
        ax.plot(yLim,[x, x], linewidth=1, color='black')

def main():
    rawFile = 'D:\\data\\StrokeMTEP\\SHAM_Groups_avg_reorganized.mat'
    rawFile2 = 'D:\\data\\StrokeMTEP\\PT_Groups_avg_reorganized.mat'
    diffFile = 'D:\\data\\StrokeMTEP\\MTEP_PT-Veh_PTAvg.mat'
    maskFile = 'D:\\data\\atlas.mat'
    figFile = 'C:\\Users\\Kenny\\Desktop\\MTEP_effect_with_PT.png'

    #f = h5py.File(Path(rawFile),'r')
    #vehData = np.array(f['Veh'])
    f = h5py.File(Path(rawFile2),'r')
    vehData = np.array(f['Veh_PT'])
    mtepData = np.array(f['MTEP_PT'])
    f = h5py.File(Path(diffFile),'r')
    diffData = np.array(f['diff'])
    f = h5py.File(Path(rawFile),'r')
    boundaries = np.array(f['regionStart'])
    boundaries = boundaries.astype(int)
    ticLoc = np.array(f['tickInd'])
    ticLoc = ticLoc.astype(int)
    ticLoc = ticLoc.tolist()
    ticLoc = ticLoc[0]
    print((vehData.shape) + (3,))
    data = np.zeros(vehData.shape + (3,))
    data[:,:,0] = mtepData
    data[:,:,1] = vehData
    data[:,:,2] = diffData
    print(data[:,:,0])

    clim = np.zeros((2,3))
    clim[:,0] = np.array([-1, 1])
    clim[:,1] = np.array([-1, 1])
    clim[:,2] = np.array([-0.3, 0.3])

    # plot
    fig, axes = plt.subplots(nrows=1,ncols=3)
    fig.set_size_inches(18,10)
    for ax, ind in zip(axes, range(0,3)):
        print(ind)
        imagesc(ax,data[:,:,ind],clim[:,ind],boundaries,ticLoc)
    plt.tight_layout()
    plt.show()

    fig.savefig(figFile, format='png')
    print('fig saved')

if __name__ == "__main__":
    main()
