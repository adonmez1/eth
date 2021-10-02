clear all
cd 'your-directory'
tic

load('price.mat'); %this is the hourly ETH-USD price data downloaded from https://min-api.cryptocompare.com/
ptable=flip(price.Variables);   %put it in oldest-to-newest order
clear price

%raw block data sets are named as block_1, block_2,... and transaction data
%sets are named as transaction_1, transaction_2,...

data_file_count = 3; % adjust this according to the number of data files that will be processed

for i=1:data_file_count
    
fileblocks=sprintf('block_%d.csv', i);
filetrans=sprintf('transaction_%d.csv', i);
    if exist(fileblocks, 'file')
        fileID=fopen(fileblocks);
        B=textscan(fileID, '%d %*s %*s %*s %*s %*s %*s %*s %*s %s %f %*f %d %*s %f %f %f %d %f' , 'Delimiter', ',', 'HeaderLines', 1);
        fclose(fileID);
    else
        break;
    end
    if exist(filetrans, 'file')
        fileID=fopen(filetrans);
        T=textscan(fileID, '%*s %d %*s %d %d %s %s %f %f %f %s %f %f %f %d', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(fileID);
    else
        break;
    end

%Below eliminates rows with 0 transaction number
for hh=[1 2 3 4 5 6 7 9]
B{hh}(B{8}==0)=[];
end
B{8}(B{8}==0)=[];

%NO NEED TO CREATE NEW VARIABLES and eat memory
[~,indB]=sort(B{7});    %store index by timestamp in indB; 
for kk=1:size(B,2)
    B{kk}=B{kk}(indB);   %B is now sorted by timestamp <=> block_nr
end
clear indB

%Below is to merge price data with block data
time=round(B{7}/3600)*3600;
[~,y]=ismember(time, ptable(:,1)); %finds joint hourly time from block and price data, first location in ptable
yy=unique(y);   %y is sorted and yy is sorted
t=ptable(yy,:);     %the relevant price data rows

price=[];
for ff=1:length(yy)    %only 25 hours
    price=[price;repmat(t(ff,2:end),sum(y==yy(ff)),1)];
end
    
block_str=string(B{2});

[~,indT]=sort(T{2});
for uu=1:size(T,2)
    T{uu}=T{uu}(indT);
end
clear indT
    
%Below is to merge transaction data with block-price data
[~,k]=ismember(B{1},T{2});
k(end+1)=size(T{1},1)+1;
kk=diff(k);

counter=1;
    for j=1:size(B{1},1)
        Block_Str(counter:(counter+kk(j)-1),:)=[repmat(block_str(j),kk(j),1)];
        counter=counter+kk(j);
    end

p_kk=repmat(kk,1,6);
b_kk=repmat(kk,1,1);
Price_Num=cell2mat(arrayfun(@(a,r)repmat(a,r,1),price,p_kk,'uni',0));

Block_Num=cell2mat(arrayfun(@(a,r)repmat(a,r,1),[B{1} B{4} B{5} B{6} B{7} B{8}],p_kk,'uni',0));
difficulty=cell2mat(arrayfun(@(a,r)repmat(a,r,1),[B{3}],b_kk,'uni',0));
base_fee=cell2mat(arrayfun(@(a,r)repmat(a,r,1),[B{9}],b_kk,'uni',0));

fileblocks=sprintf('dataset%d.txt', i);
id=fopen(fileblocks,'a');

for ii=1:length(T{1})
tmp=char(T{9}(ii));   %will only take 10 symbols from T9
fprintf(id, '%f,%f,%s,%s,%.0f,%.0f,%.0f,%s,%.0f,%.0f,%d,%s,%.0f,%f,%f,%.0f,%.0f,%.0f,%f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.0f\n',T{1}(ii),T{3}(ii),char(T{4}(ii)),char(T{5}(ii)),T{6}(ii),T{7}(ii),T{8}(ii),tmp(1:min(end,10)),T{11}(ii),T{12}(ii),T{13}(ii),Block_Str(ii,:),Block_Num(ii,5),Block_Num(ii,1:4),difficulty(ii),Block_Num(ii,6),Price_Num(ii,:), base_fee(ii));
end
fclose(id);

clear B Block_Num block_str Block_Str counter i id ID yy ii k fileID y kk p_kk p_kk2 price Price_Num t T time b_kk tmp ff hh uu fileblocks filetrans difficulty base_fee

end
toc
