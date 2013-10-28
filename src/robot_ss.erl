%% Copyright
-module(robot_ss).
-author("lfc").

-compile([{parse_transform, lager_transform}]).

-behaviour(supervisor).

%% API
-export([start_link/1]).

%% supervisor callback
-export([init/1]).

start_link([RobotStartId, RobotCount, RunningRobotsCount, ServerAddr]) ->
  lager:start(),

  ReadyRobotIds = lists:seq(RobotStartId, RobotStartId + RobotCount - 1),
  supervisor:start_link({local, robot_super_supervisor}, ?MODULE, [ReadyRobotIds]),

  ok = gen_server:call(robot_status, {set, server_addr, ServerAddr}),
  lager:info("Server address is ~p.~n", [ServerAddr]),

  gen_server:cast(robot_scheduler, {start_robot, RunningRobotsCount}),

  {ok, self()}.

init(ReadyRobotIds) ->
  SupervisorSpec = {one_for_one, 1, 60},
  RobotStateServerSpec = {robot_state_server, {robot_status, start_link, []}, permanent, brutal_kill, worker, [robot_status]},
  RobotSchedulerSpec = {robot_scheduler_server, {robot_scheduler, start_link, ReadyRobotIds}, permanent, brutal_kill, worker, [robot_scheduler]},
  ChildrenSpec = [RobotStateServerSpec, RobotSchedulerSpec],
  {ok, {SupervisorSpec, ChildrenSpec}}.
