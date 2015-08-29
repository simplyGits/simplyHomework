#!/usr/bin/env node
var util=require("util");

REQ=require("./planner")
H=REQ.HomeworkDescription
P=REQ.Planner
function inspect(o){console.log(util.inspect(o,{depth:8}));}
function startOfDay(date){return new Date(date.getFullYear(),date.getMonth(),date.getDate());}
function addDays(date,ndays){return new Date(date.getTime()+ndays*24*3600*1000);}
function diffDays(d1,d2){return ~~((d2.getTime()-d1.getTime())/(24*3600*1000));}
p=new P
p.learn(H("ne",[[1,1],[1,2]]),1500)
p.learn(H("ne",[[1,5]]),900)
p.learn(H("ne",[[1,9]]),2000)
inspect(p.persistable())
p.estimate(H("ne",[[1,5]]))
p.estimate(H("ne",[[1,4]]))
var now=new Date,today=startOfDay(now)
var schedule=p.plan(
	[
		H("ne",[[1,2]],addDays(today,2),"id 1"),
		H("ne",[[1,1],[1,5]],addDays(today,1),"id 2"),
		H("ne",[[1,9]],addDays(today,2),"id 3")
	],
	function(day){return [1,1,1,1,1,1,1,1,1,1,1,1,1,1][diffDays(today,day)];},
	now //any date on this day; `plan` applies startOfDay
)
inspect(schedule)
console.log(JSON.stringify(schedule))
