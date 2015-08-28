#!/usr/bin/env node
var util=require("util");

REQ=require("./planner")
H=REQ.HomeworkDescription
P=REQ.Planner
function inspect(o){console.log(util.inspect(o,{depth:8}));}
function startOfDay(date){return new Date(date.getFullYear(),date.getMonth(),date.getDate());}
function addDays(date,ndays){return new Date(date.getTime()+ndays*24*3600*1000);}
p=new P
p.learn(H("ne",[[1,1],[1,2]]),1500)
p.learn(H("ne",[[1,5]]),900)
p.learn(H("ne",[[1,9]]),2000)
inspect(p.persistable())
p.estimate(H("ne",[[1,5]]))
p.estimate(H("ne",[[1,4]]))
var schedule=p.plan(
	[
		H("ne",[[1,2]],addDays(startOfDay(new Date),2),"id 1"),
		H("ne",[[1,1],[1,5]],addDays(startOfDay(new Date),1),"id 2"),
		H("ne",[[1,9]],addDays(startOfDay(new Date),2),"id 3")
	],
	[1,1,1,1].map(p.availableTimeConvert),
	new Date
)
inspect(schedule)
console.log(JSON.stringify(schedule))
