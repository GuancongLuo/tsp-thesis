function [IMG_SP, IMG_label, IMG_K] = zU_relabel_SP(IMG_SP, IMG_label, final)
    last_k = 1;
    for k=1:numel(IMG_SP)
        if ~final || IMG_SP(k).N>0
            if (k~=last_k)
                % move the super pixel to the empty one
                IMG_SP(last_k) = IMG_SP(k);
                IMG_SP(k) = [];

                % relabel the pixels
                IMG_label(IMG_label==k) = last_k;
            end
            last_k = last_k + 1;
        end
    end
    IMG_K = last_k-1;
end