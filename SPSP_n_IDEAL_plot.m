% plotting for SPSP Spiral and IDEAL Spiral
        nslices=1
        ntimesteps=1
        nmeta=4  %spsp=4；IDEAL=5.
        for l5=1:nslices
            scale = 1.5*ones(ntimesteps,1)* ...
                squeeze(max(max(max(bbabs(:,:,:,:,l5),[],1),[],2),[],3)).';
            imagesc_row(bbabs(:,:,:,:,l5),[],1./scale);
            figstr = sprintf('P%05d Exam%d Series%d Slice%d',...
                h.image.rawrunnum,h.exam.ex_no,h.series.se_no,l5);
            ylstr = '';
            lm=nmeta:-1:1, ylstr = sprintf('%s  %s',ylstr,metstr{lm}); 
            xlabel('time steps');
            ylabel(ylstr);
            pos = get(gca,'Position');
            set(gca,'Position',pos.*[0.6 1 1.15 1]);
            
        end

