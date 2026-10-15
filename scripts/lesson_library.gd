extends RefCounted
class_name LessonLibrary

const LESSONS := {
	"maths_g10_linear": {
		"grade": 10,
		"subject": "Mathematics",
		"title": "Solving linear equations",
		"objective": "Solve linear equations using inverse operations.",
		"explanation": "To solve 3x + 7 = 22, subtract 7 from both sides to get 3x = 15. Divide both sides by 3, giving x = 5.",
		"question": "Solve: 4x + 6 = 30. Enter the value of x.",
		"answer": "6",
		"feedback": "Subtract 6 from both sides, then divide by 4. The answer is x = 6."
	},
	"science_g10_motion": {
		"grade": 10,
		"subject": "Physical Sciences",
		"title": "Average speed",
		"objective": "Calculate average speed from distance and elapsed time.",
		"explanation": "Average speed is total distance divided by total time. A vehicle travelling 120 km in 2 hours has an average speed of 60 km/h.",
		"question": "A learner walks 300 metres in 60 seconds. What is the average speed in m/s?",
		"answer": "5",
		"feedback": "Divide 300 metres by 60 seconds to obtain 5 m/s."
	},
	"geography_g10_weather": {
		"grade": 10,
		"subject": "Geography",
		"title": "Weather and climate",
		"objective": "Distinguish short-term weather from long-term climate.",
		"explanation": "Weather describes atmospheric conditions over a short period. Climate describes patterns of weather measured over a long period, typically decades.",
		"question": "Does today's rainfall describe weather or climate? Type one word.",
		"answer": "weather",
		"feedback": "Today's rainfall is weather because it is a short-term condition."
	}
}

static func lesson_ids() -> Array:
	return LESSONS.keys()

static func get_lesson(id: String) -> Dictionary:
	return LESSONS.get(id, {}).duplicate(true)

static func check_answer(id: String, response: String) -> bool:
	var lesson := get_lesson(id)
	if lesson.is_empty():
		return false
	return response.strip_edges().to_lower() == str(lesson["answer"]).to_lower()
