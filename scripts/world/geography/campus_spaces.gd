extends RefCounted
## Source building identity is real; all named interior layouts/notes are game design.
const SITES := {
	"library":{"osm":"way/891012679","name":"图书馆","number":"01","floors":["library","library_reading"]},
	"main_hall":{"osm":"way/891012808","name":"九教","number":"02","floors":["main_hall","main_teaching"]},
	"activity":{"osm":"way/925596040","name":"活动中心","number":"03","floors":["activity","activity_stage"]},
	"lecture":{"osm":"way/891012656","name":"西阶梯教室","number":"04","floors":["lecture"]},
	"teaching":{"osm":"way/335231659","name":"第二十六教学楼","number":"05","floors":["teaching","teaching_lab"]},
	"dorm_north":{"osm":"way/891012793","name":"37斋","number":"06","floors":["dorm_north","dorm_rooms"]},
	"dorm_west":{"osm":"way/335225865","name":"鹏翔3斋","number":"07","floors":["dorm_west","dorm_west_rooms"]},
	"canteen_north":{"osm":"way/865345217","name":"学一食堂","number":"08","floors":["canteen_north","canteen_prep"]},
	"canteen_west":{"osm":"way/335224716","name":"学五食堂","number":"09","floors":["canteen_west"]},
	"swim":{"osm":"way/891012774","name":"游泳馆","number":"10","floors":["swim","swim_plant"]},
	"gym":{"osm":"way/925596046","name":"健身馆","number":"11","floors":["gym"]},
	"network":{"osm":"way/1334514076","name":"信息与网络中心","number":"12","floors":["network","network_control"]}
}
const ROOMS := {
	"library":{"title":"图书馆 · 1F 档案区","size":Vector2(32,24),"layout":"legacy","note":"借阅登记册的最后一行只写着“纸上地图没有电也能用”。值班员把防汛档案放在北侧柜里，二楼阅览桌还留着没收走的书。"},
	"main_hall":{"title":"九教 · 1F 检修间","size":Vector2(32,24),"layout":"legacy","note":"旧手套压在检修单上。有人在A支路旁重重画了一个圈，又在下面补了一句：“灯不能全灭，活动中心还有人在等。”"},
	"activity":{"title":"活动中心 · 1F 补给站","size":Vector2(32,24),"layout":"legacy","note":"床头的小纸条写着：“回来先喝口热水，别把湿外套放到枕头上。”二楼的排练节目单还没撤下，舞台侧门留着通道。"},
	"library_reading":{"title":"图书馆 · 2F 阅览与书库","size":Vector2(38,28),"layout":"reading","note":"旧校园路线图摊在靠窗桌上，铅笔从图书馆一路划到食堂，再绕回宿舍。书签上写着：“走大路，别抄池边近道。”"},
	"main_teaching":{"title":"九教 · 2F 教室与教研室","size":Vector2(38,28),"layout":"classrooms","note":"黑板上剩着一道没擦完的题，答案被人写在了教研室门背后。备课桌上多出两把伞，旁边写着“借走记得还”。"},
	"activity_stage":{"title":"活动中心 · 2F 排练与舞台","size":Vector2(40,30),"layout":"stage","note":"节目单上最后一场演出被圈了起来：“雨停了再演，不取消。”侧台堆着空箱，观众席最前排留了两张座位。"},
	"lecture":{"title":"西阶梯教室 · 报告厅","size":Vector2(40,30),"layout":"auditorium","note":"讲义的页角折成了小三角，投影停在“下一次继续”。最后离开的人把话筒放回了原位，却忘了拿走保温杯。"},
	"teaching":{"title":"二十六教 · 1F 教学区","size":Vector2(38,28),"layout":"classrooms","note":"走廊的课表上有人画了一条很长的返校路线。三间教室的窗都关好了，讨论室门口留着一张“楼上还有人”的便条。"},
	"teaching_lab":{"title":"二十六教 · 2F 实验教学区","size":Vector2(38,28),"layout":"laboratory","note":"封存登记簿的最后一页写着：“实验延期，别把人也留在这里等。”器材已经罩好，准备间里还有一箱没拆封的纸巾。"},
	"dorm_north":{"title":"37斋 · 1F 公共区","size":Vector2(30,30),"layout":"dorm_lounge","note":"值班桌上写着：“回来记得关走廊灯，给晚归的人留门厅那一盏。”自习区的椅子推得很齐，洗衣间却剩着一只袜子。"},
	"dorm_rooms":{"title":"37斋 · 2F 宿舍走廊","size":Vector2(34,30),"layout":"dorm_rooms","note":"书桌上的便条提醒同伴还书，末尾补着：“我到食堂找你。”空床叠好了被子，行李箱的轮子上还沾着湿泥。"},
	"dorm_west":{"title":"鹏翔3斋 · 1F 洗衣与自习","size":Vector2(34,28),"layout":"laundry","note":"洗衣间的轮值表已经褪色，新添的一行是“谁先回来谁收衣服”。晾衣架旁挂着一把倒置的伞，水已经滴干了。"},
	"dorm_west_rooms":{"title":"鹏翔3斋 · 2F 起居房间","size":Vector2(34,30),"layout":"dorm_rooms","note":"有人把归还图书的纸条压在台灯下，又在背面写：“窗关了，饭在保温盒里。”楼梯前室的储物柜空出了一格。"},
	"canteen_north":{"title":"学一食堂 · 1F 餐厅","size":Vector2(40,30),"layout":"dining","note":"餐牌背面留着值班字条：“最后一锅留给来得晚的人。”取餐窗口已经擦净，后侧备餐层还亮着一盏灯。"},
	"canteen_prep":{"title":"学一食堂 · 2F 备餐与储藏","size":Vector2(36,28),"layout":"kitchen","note":"物资签收簿里夹着一张不算账的清单：热水、干毛巾、能坐下的地方。有人在“热水”下面划了两道线。"},
	"canteen_west":{"title":"学五食堂 · 餐厅与窗口","size":Vector2(36,28),"layout":"dining","note":"靠窗长桌留着两个餐盘，一张字条压在勺子下：“去宿舍送伞了，别帮我收。”窗口前的队列牌还指着同一个方向。"},
	"swim":{"title":"游泳馆 · 池畔与更衣区","size":Vector2(40,30),"layout":"pool","note":"池畔的值班记录最后一行写着：“已清场，钥匙交到门厅。”更衣区最里侧的柜门半掩着，里面只剩一顶旧泳帽。"},
	"swim_plant":{"title":"游泳馆 · 后勤设备层","size":Vector2(36,28),"layout":"plant","note":"后勤工位上留着一副耳塞和一张交接条：“声音不对就叫人，别一个人硬撑。”储物架上每个空位都画着原来工具的轮廓。"},
	"gym":{"title":"健身馆 · 训练与器材间","size":Vector2(40,30),"layout":"gym","note":"训练板上写着：“今天不计次数，回来就算。”器材间的球都装进了网袋，拉伸垫却还铺在原来的位置。"},
	"network":{"title":"网络中心 · 1F 机房","size":Vector2(36,28),"layout":"servers","note":"机柜风扇声淹没了窗外的雨。巡检单旁贴着一句：“先确认人在不在，再确认灯亮不亮。”值班室在楼上。"},
	"network_control":{"title":"网络中心 · 2F 值班与控制室","size":Vector2(36,28),"layout":"control","note":"值班记录的最后一条是“东门已回话”。监看台旁放着半杯冷茶，资料间门口的椅子被人让开了一点。"}
}

static func building(room: String) -> String:
	for id: String in SITES:
		if room in SITES[id].floors:return id
	return ""

static func ground(room: String) -> String:
	return SITES[building(room)].floors[0]

static func partner(room: String) -> String:
	var floors: Array=SITES[building(room)].floors
	if floors.size()<2:return ""
	return floors[1] if room==floors[0] else floors[0]

static func stair_x(room: String) -> float:
	return -3.6 if room=="activity" else float(ROOMS[room].size.x)*.5-2.0
