import math
import random
from panda3d.core import AmbientLight, DirectionalLight, Geom, GeomNode, GeomTriangles, GeomVertexData, GeomVertexFormat, GeomVertexWriter, TextNode, Vec3, WindowProperties, ClockObject
from direct.showbase.ShowBase import ShowBase
from direct.gui.OnscreenText import OnscreenText
from direct.task import Task


def cube(parent, name, position, scale, color):
    data = GeomVertexData(name, GeomVertexFormat.getV3(), Geom.UHStatic)
    vertices = GeomVertexWriter(data, "vertex")
    faces = [
        ((-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (-0.5, 0.5, -0.5)),
        ((-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, -0.5, 0.5)),
        ((-0.5, -0.5, -0.5), (-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (0.5, -0.5, -0.5)),
        ((0.5, 0.5, -0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5)),
        ((-0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (-0.5, -0.5, 0.5), (-0.5, -0.5, -0.5)),
        ((0.5, -0.5, -0.5), (0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5)),
    ]
    triangles = GeomTriangles(Geom.UHStatic)
    for face in faces:
        base = vertices.getWriteRow()
        for point in face:
            vertices.addData3(*point)
        triangles.addVertices(base, base + 1, base + 2)
        triangles.addVertices(base, base + 2, base + 3)
    geometry = Geom(data)
    geometry.addPrimitive(triangles)
    node = GeomNode(name)
    node.addGeom(geometry)
    model = parent.attachNewNode(node)
    model.setPos(*position)
    model.setScale(*scale)
    model.setColor(*color)
    model.setTwoSided(True)
    return model


class LivingWorld(ShowBase):
    def __init__(self):
        super().__init__()
        self.disableMouse()
        self.win.setClearColor((0.62, 0.79, 0.91, 1))
        props = WindowProperties()
        props.setTitle("The Living World | Prototype 0.1")
        self.win.requestProperties(props)
        self.keys = {key: False for key in ("w", "a", "s", "d", "shift")}
        for key in self.keys:
            self.accept(key, self.set_key, [key, True])
            self.accept(key + "-up", self.set_key, [key, False])
        self.accept("escape", self.userExit)
        self.accept("f1", self.toggle_director)
        self.accept("tab", self.switch_character)
        self.accept("1", self.set_time_scale, [1])
        self.accept("2", self.set_time_scale, [6])
        self.accept("3", self.set_time_scale, [18])
        self.accept("p", self.toggle_npcs)
        self.accept("n", self.toggle_night)
        self.director = False
        self.npcs_paused = False
        self.night = False
        self.time_scale = 6
        self.game_minutes = 7 * 60 + 45
        self.control_robot = False
        self.elapsed = 0.0
        self.setup_world()
        self.setup_ui()
        self.taskMgr.add(self.update, "world-update")

    def set_key(self, key, value):
        self.keys[key] = value

    def setup_world(self):
        self.render.setShaderAuto()
        ambient = AmbientLight("ambient")
        ambient.setColor((0.67, 0.67, 0.67, 1))
        self.render.setLight(self.render.attachNewNode(ambient))
        sun = DirectionalLight("sun")
        sun.setColor((0.8, 0.78, 0.7, 1))
        sun_node = self.render.attachNewNode(sun)
        sun_node.setHpr(-30, -55, 0)
        self.render.setLight(sun_node)
        cube(self.render, "ground", (0, 0, -0.35), (85, 85, 0.6), (0.44, 0.62, 0.38, 1))
        cube(self.render, "courtyard", (0, 3, -0.025), (28, 22, 0.08), (0.76, 0.7, 0.57, 1))
        for x, y, w, d in [(-17, 7, 9, 28), (17, 7, 9, 28), (0, 23, 30, 7)]:
            cube(self.render, "classroom-block", (x, y, 2), (w, d, 4), (0.91, 0.79, 0.57, 1))
            cube(self.render, "roof", (x, y, 4.25), (w + 0.8, d + 0.8, 0.5), (0.35, 0.39, 0.44, 1))
        for x in (-17, 17):
            for y in (-2, 5, 12, 19):
                side = 1 if x < 0 else -1
                cube(self.render, "window", (x + side * 4.52, y, 2.35), (0.09, 2.2, 1.3), (0.3, 0.58, 0.67, 1))
        for x, y in [(-30, -12), (30, -13), (-28, 30), (29, 31), (-6, -27), (8, -30)]:
            cube(self.render, "tree-trunk", (x, y, 1.8), (0.65, 0.65, 3.6), (0.4, 0.25, 0.12, 1))
            cube(self.render, "tree-canopy", (x, y, 4.5), (4.5, 4.5, 3.3), (0.2, 0.43, 0.21, 1))
        self.student = self.render.attachNewNode("student")
        cube(self.student, "legs", (0, 0, 0.5), (0.7, 0.45, 1), (0.15, 0.19, 0.3, 1))
        cube(self.student, "uniform", (0, 0, 1.45), (0.95, 0.55, 0.9), (0.16, 0.3, 0.66, 1))
        cube(self.student, "head", (0, 0, 2.2), (0.65, 0.6, 0.65), (0.38, 0.22, 0.16, 1))
        self.student.setPos(0, -8, 0)
        self.robot = self.render.attachNewNode("robot")
        cube(self.robot, "base", (0, 0, 0.3), (0.9, 0.8, 0.55), (0.25, 0.31, 0.36, 1))
        cube(self.robot, "body", (0, 0, 1.05), (1.05, 0.85, 1.1), (0.78, 0.85, 0.88, 1))
        cube(self.robot, "face", (0, -0.46, 1.3), (0.72, 0.08, 0.4), (0.1, 0.32, 0.46, 1))
        self.robot.setPos(4, 0, 0)
        self.npcs = []
        rng = random.Random(14)
        for i in range(12):
            npc = self.render.attachNewNode("student-npc")
            cube(npc, "uniform", (0, 0, 1), (0.7, 0.5, 1.35), (0.13, 0.26 + (i % 3) * 0.06, 0.58, 1))
            cube(npc, "head", (0, 0, 1.95), (0.55, 0.5, 0.55), (0.38, 0.24, 0.17, 1))
            npc.setPos(rng.uniform(-10, 10), rng.uniform(-5, 15), 0)
            self.npcs.append((npc, rng.random() * math.tau, rng.uniform(0.3, 0.9)))

    def setup_ui(self):
        self.hud = OnscreenText(text="", pos=(-1.28, 0.9), scale=0.055, align=TextNode.ALeft, fg=(1, 1, 1, 1), shadow=(0, 0, 0, 1))
        self.help = OnscreenText(text="WASD Move | Shift Run | Tab Switch | F1 Director | Esc Quit", pos=(0, -0.92), scale=0.042, fg=(1, 1, 1, 1), shadow=(0, 0, 0, 1))
        self.director_text = OnscreenText(text="", pos=(0.52, 0.75), scale=0.048, align=TextNode.ALeft, fg=(1, 1, 0.83, 1), shadow=(0, 0, 0, 1))

    def toggle_director(self):
        self.director = not self.director

    def switch_character(self):
        if self.director:
            self.control_robot = not self.control_robot

    def set_time_scale(self, value):
        if self.director:
            self.time_scale = value

    def toggle_npcs(self):
        if self.director:
            self.npcs_paused = not self.npcs_paused

    def toggle_night(self):
        if self.director:
            self.night = not self.night
            self.win.setClearColor((0.05, 0.08, 0.16, 1) if self.night else (0.62, 0.79, 0.91, 1))

    def update(self, task):
        dt = min(ClockObject.getGlobalClock().getDt(), 0.08)
        self.elapsed += dt
        self.game_minutes = (self.game_minutes + dt * self.time_scale) % 1440
        active = self.robot if self.control_robot else self.student
        dx = int(self.keys["d"]) - int(self.keys["a"])
        dy = int(self.keys["w"]) - int(self.keys["s"])
        length = math.hypot(dx, dy)
        if length:
            speed = 9 if self.keys["shift"] else 5
            active.setX(max(-39, min(39, active.getX() + dx / length * speed * dt)))
            active.setY(max(-39, min(39, active.getY() + dy / length * speed * dt)))
        if not self.npcs_paused:
            for npc, phase, speed in self.npcs:
                npc.setX(npc.getX() + math.cos(self.elapsed * 0.35 + phase) * speed * dt)
                npc.setY(npc.getY() + math.sin(self.elapsed * 0.35 + phase) * speed * dt)
        target = active.getPos()
        self.camera.setPos(target + Vec3(0, -18, 11))
        self.camera.lookAt(target + Vec3(0, 0, 1.3))
        hours = int(self.game_minutes // 60)
        minutes = int(self.game_minutes % 60)
        character = "ROBOT" if self.control_robot else "STUDENT"
        self.hud.setText(f"THE LIVING WORLD  |  Prototype 0.1\nMonday - Term 1  |  {hours:02d}:{minutes:02d}\nCharacter: {character}  |  NPCs: {len(self.npcs)}")
        self.director_text.setText(
            "DIRECTOR SANDBOX\nTab: Student / Robot\n1: Real time  2: 6x  3: 18x\nP: Pause NPCs  N: Toggle sky\nSpeed: " + str(self.time_scale) + "x\nNPCs: " + ("Paused" if self.npcs_paused else "Active")
            if self.director else ""
        )
        return Task.cont


if __name__ == "__main__":
    LivingWorld().run()
