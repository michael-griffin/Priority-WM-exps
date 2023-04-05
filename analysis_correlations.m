%Written by Michael Griffin 5/1/2016
%Calculates correlations between working memory, recall accuracy, and selectivity.

pkg load io %in Octave, allows xlswrite/xlsread

exp = 1;
exclude = 1;

[wmdata, ~, rawwmdata] = xlsread(['data/fullwmsummary_exp' num2str(exp), '.xlsx']); %should be identical to allscoresnan
[recalldata, ~, rawrecalldata] = xlsread(['data/fullrecallaccuracy_exp', num2str(exp), '.xlsx']); %Should be identical to recallsummary

if exclude
    %Find subjects where overall accuracy was either 0 or they only got one word right.
    if exp == 1 || exp == 2
        toremove = find(recalldata(:,2) < (1/54 + .001));
    elseif exp == 3
        toremove = find(recalldata(:,2) < (5/105 + .001));
        for n = 4:8 %list by list accuracy. If any lists' accuracy is 0, exclude.
            toremove = [toremove; find(recalldata(:,n) == 0)];
        end
        toremove = unique(toremove);
    end


    wmdata(toremove,:) = [];
    recalldata(toremove,:) = [];
    rawwmdata(toremove+1,:) = [];
    rawrecalldata(toremove+1,:) = [];
end


%Correlation tests:
nsubs = size(recalldata(:,1));

corrmatrix = [wmdata(:,2), recalldata(:,2:3)]; %WM, Acc, Selectivity
[rvals, pvals] = corrcoef(corrmatrix)

