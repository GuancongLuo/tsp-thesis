% =============================================================================
% == switch_move.cpp
% == --------------------------------------------------------------------------
% == A MEX interface to perform switch moves on TSPs.
% == See m files for calling convention.
% ==
% == All work using this code should cite:
% == J. Chang, D. Wei, and J. W. Fisher III. A Video Representation Using
% ==    Temporal Superpixels. CVPR 2013.
% == --------------------------------------------------------------------------
% == Written in C++ by Jason Chang and Donglai Wei 06-20-2013
% == Converted to MATLAB by Andrew Pillsbury 12-12-2014
% =============================================================================

function [IMG_K, IMG_label, IMG_SP, IMG_SP_changed, IMG_max_UID, IMG_alive_dead_changed, IMG_SP_old] = switch_move(IMG_label, IMG_SP, IMG_K, IMG_N, IMG_SP_old, IMG_SP_changed, IMG_max_UID, IMG_max_SPs, IMG_alive_dead_changed, IMG_new_SP, model_order_params, IMG_new_pos, IMG_new_app)
    disp('switch_move');
    xdim = size(IMG_label, 1);
    empty_SPs = false(IMG_K, 1);
    for k=1:IMG_K
        if (k > numel(IMG_SP) || isempty(IMG_SP(k).N) || IMG_SP(k).N == 0) && IMG_SP_old(k)
            empty_SPs(k) = true;
        end
    end

    for k=1:IMG_K
        if (k > numel(IMG_SP) || isempty(IMG_SP(k).N) || IMG_SP(k).N == 0)
            % if old, check to see a new or unused old
            % if new, check to see if any unused old
            best_k = -1;
            best_energy = 0;
            if IMG_SP_old(k)
                delta = move_switch_calc_delta(model_order_params, IMG_SP(k), IMG_new_SP, true, false);
                if (delta > best_energy)
                    best_k = IMG_K+1;
                    best_energy = delta;
                end
            end
            found_empty_SPs = find(empty_SPs);
            for test_kindex=1:length(found_empty_SPs)
                test_k = found_empty_SPs(test_kindex);
                delta = move_switch_calc_delta(model_order_params, IMG_SP(k), IMG_SP(test_k), IMG_SP_old(k), IMG_SP_old(test_k));
                if (delta > best_energy)
                    best_k = test_k;
                    best_energy = delta;
                end
            end

            % switch with best label
            if best_k>0 && best_energy>0
%                disp('Switchin!');
                % change the labels
                found_pix = find(IMG_SP(k).pixels);
                for index=1:length(found_pix)
                    [x, y] = get_x_and_y_from_index(found_pix(index), xdim);
                    IMG_label(x, y) = best_k;
                end
                IMG_SP_changed(k) = true;
                IMG_SP_changed(best_k) = true;

                % make room for the new one
                if best_k==IMG_K+1
                    IMG_K = IMG_K+1;
                    if IMG_K>IMG_max_SPs
                        disp('Ran out of space!');
                    end
                    if (IMG_K > numel(IMG_SP) || isempty(IMG_SP(IMG_K).N) || IMG_SP(IMG_K).N == 0)
                        IMG_SP(IMG_K) = new_SP(IMG_new_pos, IMG_new_app, IMG_max_UID, [0, 0], IMG_N, IMG_max_SPs);
                        IMG_max_UID = IMG_max_UID + 1;
                    end
                else
                    IMG_alive_dead_changed = true;
                end
                
                IMG_SP = U_merge_SPs(IMG_SP, IMG_label, best_k, IMG_K);
                
                % delete it if it was a new one
                if IMG_SP_old(k)
                    % add it to the search list
                    empty_SPs(k) = true;
                    IMG_alive_dead_changed = true;
                end

                %ELSE DELETE IMG_SP(k)?
                
                % remove it from the search list
                if IMG_SP_old(best_k)
                    empty_SPs(best_k) = false;
                end

                % now update the neighbors list
                % IMG = U_fix_neighbors_self(IMG, best_k);
                % update the neighbors' neighbors
                % IMG = U_fix_neighbors_neighbors(IMG, best_k, IMG_N+1);
            end
        end
    end
end


function logprob = move_switch_calc_delta(model_order_params, oldSP, newSP, oldSP_is_old, newSP_is_old)
    logprob = SP_log_likelihood_switch_prior(oldSP, newSP, newSP_is_old);
    logprob = logprob - oldSP.log_likelihood();
    
    % if N==0 or newSP_is_old==oldSP_is_old, logprob is unchanged
    if oldSP.N>0 && newSP_is_old~=oldSP_is_old
        if newSP_is_old
            logprob = logprob + model_order_params.is_old_const - model_order_params.is_new_const;
        else
            logprob = logprob + model_order_params.is_new_const - model_order_params.is_old_const;
        end
    end
end