% all data is coming from the dzn file

enum existingVMs;   % an index of VMs. should be unique, could be VM names or any other kind of id
enum vmSizes;       % the list of Azure VM sizes we want to use in the model
enum vmDisks;       % he list ov Azure disks we want to use in the model

% existing VM attributes
array[existingVMs] of int: vmCPU;
array[existingVMs] of int: vmRAM;
array[existingVMs] of int: vmDisk;

% azure VM size numbers
array[vmSizes] of int: vmSizeCPU;
array[vmSizes] of float: vmSizeRAM;
array[vmSizes] of float: vmSizePrice;

array[vmDisks] of int: vmDiskSizes;
array[vmDisks] of float: vmDiskPrice;

% decision variables
array[existingVMs] of var vmSizes: selectedSize;
array[existingVMs] of var vmDisks: selectedDiskSize;

% the contraint
constraint forall(vm in existingVMs)(
  ((vmSizeRAM[selectedSize[vm]] - vmRAM[vm] >= 0) /\ (vmSizeRAM[selectedSize[vm]] - vmRAM[vm] <= 64)) /\
  ((vmSizeCPU[selectedSize[vm]] - vmCPU[vm] >= 0) /\ (vmSizeCPU[selectedSize[vm]] - vmCPU[vm] <= 16))
);

constraint forall(vm in existingVMs)(
  vmDiskSizes[selectedDiskSize[vm]] - vmDisk[vm] >= 0
);

var float: totalPrice = sum(vm in existingVMs)(vmSizePrice[selectedSize[vm]] + vmDiskPrice[selectedDiskSize[vm]]/(30*24));

solve minimize totalPrice;


output [ "\(totalPrice):\n" ++ join("\n", ["\(vm), \(vmCPU[vm]), \(vmRAM[vm]), " ++ 
                                           "\(vmDisk[vm]), \(selectedSize[vm]), \(vmSizeCPU[selectedSize[vm]]), " ++ 
                                           "\(vmSizeRAM[selectedSize[vm]]), \(vmDiskSizes[selectedDiskSize[vm]]), " ++ 
                                           "\(vmSizePrice[selectedSize[vm]]), \(vmDiskPrice[selectedDiskSize[vm]]/(30*24))" | vm in  existingVMs]) ]