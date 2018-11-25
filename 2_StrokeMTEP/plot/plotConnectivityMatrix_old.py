import h5py
import numpy as np
from pathlib import Path
from mpl_toolkits.axes_grid1 import make_axes_locatable
import matplotlib.pyplot as plt

def saveAvg(rawFile,saveFile):
    saveFilePath = Path(saveFile + '.npz')
    if saveFilePath.is_file():
        print('file already saved')
    else:
        f = h5py.File(rawFile, 'r')

        result = f['MTEP_PT'][:,0,0]
        mtepPtNum = result.shape[0];
        result = f['Veh_PT'][:,0,0];
        vehPtNum = result.shape[0];
        result2 = f['MTEP_PT'][0,:,0];
        rowNum = result2.shape[0];

        print('Number of MTEP patients: ' + str(mtepPtNum))
        print('Number of Vehicle patients: ' + str(vehPtNum))
        print('Number of pixels: ' + str(rowNum))

        mtepAvg = np.zeros((rowNum, rowNum))
        vehAvg = np.zeros((rowNum, rowNum))

        for pt in range(0,mtepPtNum):
            print('pt # ' + str(pt))
            ptData = np.array(f['MTEP_PT'][pt,:,:]);
            ptData = np.tanh(ptData)
            mtepAvg = np.add(mtepAvg,ptData)

        mtepAvg = np.true_divide(mtepAvg,mtepPtNum)

        for pt in range(0,vehPtNum):
            print('pt # ' + str(pt))
            ptData = np.array(f['Veh_PT'][pt,:,:]);
            ptData = np.tanh(ptData)
            vehAvg = np.add(vehAvg,ptData)

        vehAvg = np.true_divide(vehAvg,vehPtNum)

        np.savez_compressed(saveFile + '.npz',mtepAvg=mtepAvg,vehAvg=vehAvg)

def organizePix(data,seedInd):
    return 0

def getSeedInd(maskFile): # gets seed indices
    f = h5py.File(Path(maskFile), 'r')
    seedInd = np.array(f['AtlasSeedsFilled'])
    for x in range(0,65):
        for y in range(0,128):
            if seedInd[x,y] !=0:
                seedInd[x,y] = seedInd[x,y] + 20;
    return seedInd

def imagesc(ax,data,clim):
    im = ax.imshow(data, interpolation='none',
                   cmap='jet')
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    plt.colorbar(im, cax=cax)

def main():
    rawFile = 'D:\\data\\StrokeMTEP\\PT_Groups_Tad_single.mat'
    saveFile = 'D:\\data\\StrokeMTEP\\PT_Groups_Avg'
    maskFile = 'D:\\data\\atlas.mat'

    saveAvg(rawFile,saveFile)

    x = np.load(saveFile + '.npz')
    mtepAvg = x['mtepAvg']
    print((mtepAvg.shape) + (3,))
    data = np.zeros(mtepAvg.shape + (3,))
    data[:,:,0] = x['vehAvg']
    data[:,:,1] = x['mtepAvg']
    data[:,:,2] = x['mtepAvg'] - x['vehAvg']
    print(data[:,:,0])

    # get mask


    clim = np.zeros((2,3))
    clim[:,0] = np.array([-1, 1])
    clim[:,1] = np.array([-1, 1])
    clim[:,2] = np.array([-0.3, 0.3])

    # plot
    fig, axes = plt.subplots(nrows=1,ncols=3)
    for ax, ind in zip(axes, range(0,3)):
        print(ind)
        imagesc(ax,data[:,:,ind],clim[:,ind])
    plt.show()

if __name__ == "__main__":
    main()
