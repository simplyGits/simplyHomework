/*
 * simplyHomework plan algorithm and stuff.
 * @author simply
 * @module planner
 */

var require = require || Npm.require;
require("js-object-clone");
var util = require("util");
var assert = require('assert');

var MIN_TIME_TASK_DAY = 450; // minimum of 7.5 minutes for one task on a day (except if expected time is <7.5 min)

/**
 * @class HomeworkDescription
 * @constructor
 * @param {any} subject Must be primitive, unique and fixed
 * @param {int[][]} locations
 * @param {Date} duedate
 * @param {any} id
 */
HomeworkDescription=function(){
	if(!(this instanceof HomeworkDescription)){
		return new (Function.prototype.bind.apply(
			HomeworkDescription,
			[null].concat(Array.prototype.slice.call(arguments))
		));
	}

	/**
	 * A unique identifier for a subject. Can be pretty much anything, lest it's
	 * a primitive type and unique and fixed, i.e. there is only one identifier
	 * per subject and only one subject per identifier.
	 *
	 * @property subject
	 * @type any
	 */
	this.subject=arguments.length>0?arguments[0]:null;

	/**
	 * Items in `location` can be multiple things, e.g.
	 *   - [chapter,paragraph,exercise]
	 *   - [bookid,page,exercise]
	 *   - [chapter,exercise]
	 *   - [bookid,page]
	 *
	 * In general, anything that can be expressed in a sequence of integers that
	 * specifies the location.  (Actually, they should be index paths — think
	 * NSIndexPath) The `location` property contains an array of those, because
	 * homework can be multiple exercises, for example.  Per subject, please use
	 * just one index convention. If you need to, add ones where you don't have
	 * entries.
	 *
	 * @property location
	 * @type int[][]
	 */
	this.location=arguments.length>1?arguments[1]:[];

	/**
	 * A Date indicating when this homework is due
	 * @prototype duedate
	 * @type Date
	 */
	this.duedate=arguments.length>2?arguments[2]:null;

	/**
	 * Some id that the outside world can decide on
	 * @property id
	 * @type any
	 */
	this.id=arguments.length>3?arguments[3]:null;
};

/**
 * @class Planner
 * @constructor
 * @param {Object} [persisted] Result from `Planner::persistable`.
 */
Planner=function(){
	if(!(this instanceof Planner))return new Planner(arguments[0]);

	/**
	 * @property isPlannerObject
	 * @type Boolean
	 * @final
	 * @default true
	 */
	this.isPlannerObject=true;

	//PREV: Object[subject id][location index path item][value of the loc. idxp. item][samples of time taken]
	//Object[subject id][loc item 0][loc item 1]...[loc item n] = time taken for that index path
	var subjects={}; //The Cache

	/**
	 * Learn.
	 * @method learn
	 * @param {HomeworkDescription} hwdesc The `HomeworkDescription` that was done.
	 * @param {Number} timetaken Number in time unit that specifies how long the given description took.
	 */
	this.learn=function(hwdesc,timetaken){
		var i,j,idx,subj,loc;
		assert(hwdesc instanceof HomeworkDescription);
		subj=hwdesc.subject;
		loc=hwdesc.location;
		assert(loc.length!=0);
		if(!subjects[subj]){
			subjects[subj]={};
		}
		var itemref;
		for(i=0;i<loc.length;i++){
			itemref=subjects[subj];
			for(j=0;j<loc[i].length;j++){
				if(j==loc[i].length-1){
					itemref[loc[i][j]]=timetaken/hwdesc.location.length;
				} else if(!itemref[loc[i][j]]){
					itemref[loc[i][j]]={};
				}
				itemref=itemref[loc[i][j]];
			}
		}
	};

	/**
	 * @method generalSubjectEstimate
	 * @param {any} subjid
	 * @param {Function} gradeFn
	 * @return {Number}
	 */
	this.generalSubjectEstimate=function(subjid,gradeFn){
		var grade=gradeFn(subjid);
		return 3600*3/2-3600*grade/10;
	};

	/**
	 * Guesses the time needed for the given `hwdesc` with a single location.
	 * @private
	 * @method _estimateSingle
	 * @param {HomeworkDescription} hwdesc
	 * @param {Function} gradeFn
	 * @return {Number}
	 */
	this._estimateSingle=function(hwdesc,gradeFn){
		assert(hwdesc instanceof HomeworkDescription);
		assert(hwdesc.location.length==1);
		if(!subjects[hwdesc.subject]){
			return this.generalSubjectEstimate(hwdesc.subject,gradeFn);
		}
		var i,itemref=subjects[hwdesc.subject];
		for(i=0;i<hwdesc.location[0].length;i++){
			if(itemref[hwdesc.location[0][i]]==null)break;
			itemref=itemref[hwdesc.location[0][i]];
		}
		if(i==hwdesc.location[0].length)return itemref;
		var key,timearr=[];
		for(key in itemref){
			timearr.push(itemref[key]);
		}
		return rms(timearr);
	};

	/**
	 * Guesses the time needed for the given `hwdesc`.
	 * @method estimate
	 * @param {HomeworkDescription} hwdesc
	 * @param {Function} gradeFn
	 * @return {Number}
	 */
	this.estimate=function(hwdesc,gradeFn){
		var subj,loc;
		assert(hwdesc instanceof HomeworkDescription);
		return sum(hwdesc.location.map(function(loc){
			return this._estimateSingle(HomeworkDescription(hwdesc.subject,[loc]),gradeFn);
		}.bind(this)));
	};

	/**
	 * Converts the current Planner to a persistable object.
	 * @method persistable
	 * @return {Object}
	 */
	this.persistable=function(){
		return Object.clone(subjects,true);
	};

	/**
	 * Loads in an object created by `Planner::persistable`.
	 * @method frompersistable
	 * @param {Object} subj The object created by `Planner:persistable` to load.
	 */
	this.frompersistable=function(subj){
		if(subj.isPlannerObject===true) //they persisted the whole object ._.
			subjects=subj.persistable();
		else subjects=Object.clone(subj,true);
	};

	/**
	 * @method availableTimeConvert
	 * @param {Number} code
	 * @return Number
	 */
	this.availableTimeConvert=function(code){
		// return [0,30*60,90*60,180*60][code];
		return (15*code*code+15*code)*60;
	};

	/**
	 * @method plan
	 * @param {HomeworkDescription[]} items
	 * @param {Function(Date) Number} availableFn Specifies the code for how much time (in time unit) there is available for the given day.
	 * @param {Date} today The date which the planner uses as "today"; will be rounded to start of day.
	 * @param {Function(String) Number} gradeFn Gets a subject identifier and must return the average grade of the student for that subject.
	 * @return {Object} The schedule.
	 */
	this.plan=function(items,availableFn,today,gradeFn){
		today=startOfDay(today);
		var availableCache=[];
		var available=(function(day){
			var targetday;
			if(day<0)assert(false);
			while(day>=availableCache.length){
				targetday=addDays(today,availableCache.length);
				availableCache.push(availableFn(targetday));
			}
			return availableCache[day];
		}).bind(this);
		items=Object.clone(items,true); //we'll modify them for our own needs
		var needed=new Array(items.length);
		var i;
		for(i=0;i<items.length;i++){
			needed[i]=this.estimate(items[i],gradeFn);
		}
		console.log(" needed =",needed);
		var maxdiff=0;
		for(i=0;i<items.length;i++){
			items[i].duedate=startOfDay(items[i].duedate);
			items[i].duediff=diffDays(today,items[i].duedate);
			if(items[i].duediff<0)items[i].duediff=0; //you're a bit late son
			maxdiff=Math.max(maxdiff,items[i].duediff);
		}
		var dueInDays=new Array(maxdiff+1);
		for(i=0;i<=maxdiff;i++)available(i);
		console.log("available =",availableCache);
		for(i=0;i<=maxdiff;i++)dueInDays[i]=[];
		for(i=0;i<items.length;i++){
			dueInDays[items[i].duediff].push({item:items[i],needed:needed[i]});
		}
		for(i=0;i<dueInDays.length;i++){
			dueInDays[i].sort(function(a,b){return a.needed<b.needed;}); //descending sort on needed time, per day
		}
		var schedule=new Array(maxdiff);
		var daylength=new Array(maxdiff);
		for(i=0;i<maxdiff;i++){
			schedule[i]=[];
			daylength[i]=0;
		}
		var workingForDay;
		var day,it,total,itemcopy,fractions,firstUsedDay,lastUsedDay,firstDayItem,lastDayItem;
		workingForDay=0;
		while(true){
			while(workingForDay<dueInDays.length&&dueInDays[workingForDay].length==0)workingForDay++;
			if(workingForDay>=dueInDays.length)break; //done!
			it=dueInDays[workingForDay].shift();
			console.log("daylength="+util.inspect(daylength)+" item={\""+it.item.subject+"\" - "+util.inspect(it.item.location)+" - due in "+it.item.duediff+" day"+(it.item.duediff==1?"":"s")+"} it.needed="+it.needed);
			for(day=0;day<it.item.duediff;day++){
				if(daylength[day]+it.needed<=available(day))break;
			}
			if(day<it.item.duediff){
				console.log(" -> planned on day "+day);
				itemcopy=Object.clone(it.item,true);
				itemcopy.timepart=it.needed;
				itemcopy.timefraction=1;
				schedule[day].push(itemcopy);
				daylength[day]+=it.needed;
			} else { //the item didn't fit anywhere
				console.log(" -> no fit found; distributing");
				total=0;
				fractions=[];
				firstUsedDay=-1;
				for(day=0;day<it.item.duediff;day++){
					itemcopy=Object.clone(it.item,true);
					itemcopy.timepart=Math.min(available(day)-daylength[day],it.needed-total);
					if(itemcopy.timepart<it.needed-total&&itemcopy.timepart<MIN_TIME_TASK_DAY)continue; //almost no time left
					if(itemcopy.timepart<=0)continue;
					itemcopy.timefraction=itemcopy.timepart/it.needed;
					if(firstUsedDay==-1)firstUsedDay=day;
					lastUsedDay=day;
					schedule[day].push(itemcopy);
					daylength[day]+=itemcopy.timepart;
					total+=itemcopy.timepart;
					fractions.push({timepart:itemcopy.timepart,day:day});
					if(total>=it.needed)break;
				}
				if(total<it.needed){
					console.log(" -> distributing left "+(it.needed-total)+" excess; putting on first used day");
					if(firstUsedDay==-1){ //HELP we didn't plan ANYTHING yet at all
						console.log(" -> NO FIRST USED DAY, so just plugging everything on day 0");
						itemcopy=Object.clone(it.item,true);
						itemcopy.timepart=it.needed;
						itemcopy.timefraction=1;
						schedule[0].push(itemcopy);
						daylength[0]+=it.needed;
						continue; //skip all the fraction stuff
					} else {
						firstDayItem=schedule[firstUsedDay][schedule[firstUsedDay].length-1];
						firstDayItem.timepart+=it.needed-total;
						firstDayItem.timefraction=firstDayItem.timepart/it.needed;
					}
					total=it.needed;
				}
				//NOT REACHED IF SHIT WAS JUST THROWN ON DAY 0 DUE TO continue ABOVE
				fractions.sort(function(a,b){a.timepart>b.timepart;}); //descending sort on timepart
				lastDayItem=schedule[lastUsedDay][schedule[lastUsedDay].length-1];
				while(fractions[0].timepart<available(lastUsedDay)-daylength[lastUsedDay]){
					schedule[fractions[0].day].pop();
					daylength[fractions[0].day]-=fractions[0].timepart;
					lastDayItem.timepart+=fractions[0].timepart;
					lastDayItem.timefraction=lastDayItem.timepart/it.needed;
					daylength[lastUsedDay]+=fractions[0].timepart;
					fractions.shift();
				}
			}
		}
		console.log("daylength="+util.inspect(daylength));
		var ret={};
		for(i=0;i<schedule.length;i++){
			if(schedule[i].length==0)continue;
			ret[addDays(today,i).getTime()]=schedule[i];
		}
		return ret;
	};



	if(arguments.length==1)subjects=Object.clone(arguments[0],true); //from a persist source
};


function startOfDay(date){
	return new Date(date.getFullYear(),date.getMonth(),date.getDate());
}
function addDays(date,ndays){
	return new Date(date.getTime()+ndays*24*3600*1000);
}
function diffDays(d1,d2){
	return ~~((d2.getTime()-d1.getTime())/(24*3600*1000));
}

function rms(arr){
	var sum,i,len;
	sum=0;
	len=arr.length;
	for(i=0;i<len;i++)sum+=arr[i]*arr[i];
	return Math.sqrt(sum/len);
}
function sum(arr){
	var sum,i,len;
	sum=0;
	len=arr.length;
	for(i=0;i<len;i++)sum+=arr[i];
	return sum;
}

if (module !== undefined) {
	module.exports= {
		HomeworkDescription: HomeworkDescription,
		Planner: Planner,
	};
}
