function parforWaitbar(waitbarHandle,iterations)

% w = waitbar(0,'Please wait ...');
% 
% % Create DataQueue and listener
% D = parallel.pool.DataQueue;
% afterEach(D,@parforWaitbar);
% 
% N = 10000;
% parforWaitbar(w,N)
% 
% 
% parfor i = 1:N
% 	% pause替换乘自己的就可以了
%     pause(rand)
%     
%     send(D,[]);
% end
% delete(w);

persistent count h N
if nargin == 2
    % Initialize

    count = 0;
    h = waitbarHandle;
    N = iterations;
else
    % Update the waitbar

    % Check whether the handle is a reference to a deleted object
    if isvalid(h)
        count = count + 1;
        waitbar(count / N,h);
    end
end
end
