import * as T from "three";

export const WOLF = new T.Vector3(0, 0, -9);
export function ground(x: number, z: number) {
    return (
        0.5 +
        0.7 * Math.sin(x * 0.13) * Math.cos(z * 0.12) +
        1.4 * Math.exp(-((x + 12) ** 2 + (z + 10) ** 2) / 95)
    );
}
export function createWorld(
    host: HTMLElement,
    position: T.Vector3,
    onNear: (v: boolean) => void,
    onInteract: () => void,
) {
    const scene = new T.Scene();
    scene.background = new T.Color("#9ccbd4");
    scene.fog = new T.FogExp2("#a8cbd1", 0.008);
    const renderer = new T.WebGLRenderer({ antialias: true });
    renderer.setPixelRatio(Math.min(devicePixelRatio, 1.7));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = T.PCFSoftShadowMap;
    renderer.outputColorSpace = T.SRGBColorSpace;
    renderer.toneMapping = T.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    host.append(renderer.domElement);
    const camera = new T.PerspectiveCamera(50, 1, 0.1, 350);
    scene.add(new T.HemisphereLight("#d0efff", "#4e6540", 2.6));
    const sun = new T.DirectionalLight("#ffe0a6", 3.4);
    sun.position.set(-25, 40, 15);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    Object.assign(sun.shadow.camera, {
        left: -45,
        right: 45,
        top: 45,
        bottom: -45,
        near: 1,
        far: 130,
    });
    sun.shadow.normalBias = 0.04;
    scene.add(sun);
    const solids: { x: number; z: number; r: number }[] = [];
    function mesh(
        g: T.BufferGeometry,
        color: string,
        x = 0,
        y = 0,
        z = 0,
        parent: T.Object3D = scene,
    ) {
        const m = new T.Mesh(
            g,
            new T.MeshStandardMaterial({ color, roughness: 0.85 }),
        );
        m.position.set(x, y, z);
        m.castShadow = true;
        m.receiveShadow = true;
        parent.add(m);
        return m;
    }
    const terrain = new T.PlaneGeometry(66, 66, 100, 100);
    terrain.rotateX(-Math.PI / 2);
    const a = terrain.attributes.position;
    const colors = [];
    for (let i = 0; i < a.count; i++) {
        const x = a.getX(i),
            z = a.getZ(i),
            r = Math.hypot(x, z);
        a.setY(i, ground(x, z) - Math.max(0, r - 24) * 0.8);
        const c = new T.Color(
            r > 23
                ? "#d9c58f"
                : Math.abs(x - 2 * Math.sin(z * 0.2)) < 1.7
                  ? "#c1ad7d"
                  : "#6f9660",
        );
        c.multiplyScalar(0.92 + 0.08 * Math.sin(x * 3 + z * 2));
        colors.push(c.r, c.g, c.b);
    }
    terrain.setAttribute("color", new T.Float32BufferAttribute(colors, 3));
    terrain.computeVertexNormals();
    const land = new T.Mesh(
        terrain,
        new T.MeshStandardMaterial({ vertexColors: true, roughness: 1 }),
    );
    land.receiveShadow = true;
    scene.add(land);
    const waterGeo = new T.PlaneGeometry(600, 600, 100, 100);
    waterGeo.rotateX(-Math.PI / 2);
    const water = new T.Mesh(
        waterGeo,
        new T.MeshStandardMaterial({
            color: "#238e9b",
            metalness: 0.35,
            roughness: 0.3,
            transparent: true,
            opacity: 0.9,
        }),
    );
    water.position.y = -1.1;
    scene.add(water);
    // Deterministic dressing keeps reloads and camera comparisons reproducible.
    let seed = 23;
    const rand = () => {
        seed = (seed * 1664525 + 1013904223) >>> 0;
        return seed / 4294967296;
    };
    const leaves: T.Mesh[] = [];
    for (let i = 0; i < 66; i++) {
        const x = (rand() - 0.5) * 48,
            z = (rand() - 0.5) * 48;
        if (
            Math.hypot(x, z) > 24 ||
            Math.abs(x) < 4 ||
            Math.hypot(x + 8, z - 9) < 6
        )
            continue;
        const y = ground(x, z);
        const h = 2 + rand() * 3;
        mesh(
            new T.CylinderGeometry(0.18, 0.32, h, 7),
            "#705a41",
            x,
            y + h / 2,
            z,
        );
        solids.push({ x, z, r: 0.55 });
        const crown = mesh(
            new T.IcosahedronGeometry(h * 0.65, 1),
            ["#36785e", "#4b8662", "#658d58"][i % 3],
            x,
            y + h,
            z,
        );
        crown.scale.y = 0.8;
        leaves.push(crown);
    }
    for (let i = 0; i < 120; i++) {
        const x = (rand() - 0.5) * 50,
            z = (rand() - 0.5) * 50;
        if (Math.hypot(x, z) > 24 || Math.abs(x) < 2) continue;
        const r = 0.12 + rand() * 0.55;
        const m = mesh(
            new T.DodecahedronGeometry(r, 0),
            i % 4 ? "#809083" : "#b5a9a0",
            x,
            ground(x, z) + r * 0.3,
            z,
        );
        m.scale.y = 0.65;
    }
    for (let i = 0; i < 240; i++) {
        const x = (rand() - 0.5) * 47,
            z = (rand() - 0.5) * 47;
        if (Math.abs(x) < 2 || Math.hypot(x, z) > 23) continue;
        mesh(
            new T.ConeGeometry(0.07, 0.35, 3),
            i % 3 ? "#96b66d" : "#f5cf8b",
            x,
            ground(x, z) + 0.15,
            z,
        );
    }
    // A small inhabited home, with warm windows and a sheltering roof.
    mesh(new T.BoxGeometry(5, 3, 4), "#e2c99c", -8, ground(-8, 9) + 1.5, 9);
    const roof = mesh(
        new T.ConeGeometry(4.4, 2.5, 4),
        "#426c71",
        -8,
        ground(-8, 9) + 4,
        9,
    );
    roof.rotation.y = Math.PI / 4;
    solids.push({ x: -8, z: 9, r: 3.3 });
    mesh(
        new T.BoxGeometry(0.95, 1.9, 0.12),
        "#5b493c",
        -8,
        ground(-8, 9) + 0.95,
        11.1,
    );
    mesh(
        new T.BoxGeometry(0.8, 0.85, 0.12),
        "#ffdc8c",
        -6.5,
        ground(-8, 9) + 1.7,
        11.1,
    );
    for (let i = 0; i < 5; i++) {
        mesh(new T.BoxGeometry(3, 0.18, 1.3), "#8d7561", 0, -0.1, 23 + i * 1.3);
        for (const x of [-1.35, 1.35])
            mesh(
                new T.CylinderGeometry(0.1, 0.1, 3, 6),
                "#685747",
                x,
                -0.6,
                23 + i * 1.3,
            );
    }
    for (let i = 0; i < 12; i++) {
        const cloud = new T.Group();
        scene.add(cloud);
        cloud.position.set(
            (rand() - 0.5) * 200,
            25 + rand() * 12,
            (rand() - 0.5) * 200,
        );
        for (let j = 0; j < 4; j++) {
            const m = mesh(
                new T.SphereGeometry(4 + rand() * 4, 12, 8),
                "#f5eadc",
                j * 4,
                0,
                0,
                cloud,
            );
            m.scale.y = 0.4;
            m.castShadow = false;
        }
    }
    for (let i = 0; i < 5; i++) {
        const x = -95 + i * 46,
            z = -100 - rand() * 30;
        const rock = mesh(
            new T.ConeGeometry(12 + rand() * 8, 23, 6),
            "#72928a",
            x,
            5 + rand() * 10,
            z,
        );
        rock.rotation.z = Math.PI;
        mesh(
            new T.CylinderGeometry(12, 14, 2, 8),
            "#709775",
            x,
            rock.position.y + 12,
            z,
        );
    }
    const avatar = new T.Group();
    scene.add(avatar);
    mesh(new T.CapsuleGeometry(0.3, 0.65, 4, 8), "#376f83", 0, 1, 0, avatar);
    mesh(new T.SphereGeometry(0.26, 12, 8), "#e9bf96", 0, 1.75, 0, avatar);
    const hat = mesh(
        new T.ConeGeometry(0.45, 0.55, 7),
        "#314e65",
        0,
        2.04,
        0,
        avatar,
    );
    hat.rotation.z = -0.16;
    const legs = [-0.17, 0.17].map((x) =>
        mesh(
            new T.CapsuleGeometry(0.1, 0.36, 3, 6),
            "#3c4644",
            x,
            0.35,
            0,
            avatar,
        ),
    );
    mesh(new T.BoxGeometry(0.45, 0.55, 0.22), "#b99b66", 0, 1, 0.3, avatar);
    const wolf = new T.Group();
    wolf.position.set(WOLF.x, ground(WOLF.x, WOLF.z), WOLF.z);
    scene.add(wolf);
    mesh(
        new T.IcosahedronGeometry(0.7, 1),
        "#b65c35",
        0,
        0.8,
        0,
        wolf,
    ).scale.set(0.7, 0.8, 1.3);
    mesh(new T.IcosahedronGeometry(0.45, 1), "#db9b59", 0, 1.35, 0.55, wolf);
    for (const x of [-0.25, 0.25]) {
        mesh(new T.ConeGeometry(0.17, 0.45, 4), "#763f35", x, 1.8, 0.5, wolf);
        for (const z of [-0.4, 0.4])
            mesh(
                new T.CylinderGeometry(0.09, 0.13, 0.6, 5),
                "#603e36",
                x,
                0.3,
                z,
                wolf,
            );
        mesh(
            new T.SphereGeometry(0.045, 8, 6),
            "#fff4bb",
            x * 0.75,
            1.4,
            0.93,
            wolf,
        );
    }
    const ring = mesh(
        new T.TorusGeometry(1.5, 0.035, 6, 60),
        "#ffe5a0",
        0,
        ground(0, -9) + 0.08,
        -9,
    );
    ring.rotation.x = -Math.PI / 2;
    const companion = mesh(
        new T.IcosahedronGeometry(0.3, 1),
        "#8bdfd0",
        2,
        2,
        7,
    );
    const glow = new T.PointLight("#8be8d6", 2, 5);
    companion.add(glow);
    const keys = new Set<string>();
    let yaw = 0,
        pitch = 0.42,
        distance = 8,
        drag = false,
        vy = 0,
        near = false,
        last = performance.now(),
        time = 0,
        frame = 0;
    const down = (e: KeyboardEvent) => {
        if ((e.target as HTMLElement).closest("button,input,select,textarea"))
            return;
        if (
            [
                "Space",
                "KeyW",
                "KeyA",
                "KeyS",
                "KeyD",
                "ArrowUp",
                "ArrowDown",
                "ArrowLeft",
                "ArrowRight",
            ].includes(e.code)
        )
            e.preventDefault();
        keys.add(e.code);
        if (e.code === "KeyE" && near && !e.repeat) onInteract();
    };
    const up = (e: KeyboardEvent) => keys.delete(e.code);
    const blur = () => {
        keys.clear();
        drag = false;
    };
    let destination: T.Vector3 | null = null;
    let dragged = 0;
    const ray = new T.Raycaster();
    const pointerDown = (e: PointerEvent) => {
        drag = true;
        dragged = 0;
        renderer.domElement.setPointerCapture(e.pointerId);
    };
    const pointerUp = (e: PointerEvent) => {
        drag = false;
        if (dragged < 5) {
            const rect = renderer.domElement.getBoundingClientRect();
            ray.setFromCamera(
                new T.Vector2(
                    ((e.clientX - rect.left) / rect.width) * 2 - 1,
                    (-(e.clientY - rect.top) / rect.height) * 2 + 1,
                ),
                camera,
            );
            const hit = ray.intersectObject(land)[0];
            if (hit && Math.hypot(hit.point.x, hit.point.z) < 24)
                destination = hit.point.clone();
        }
    };
    const pointerMove = (e: PointerEvent) => {
        if (drag) {
            dragged += Math.abs(e.movementX) + Math.abs(e.movementY);
            yaw -= e.movementX * 0.005;
            pitch = T.MathUtils.clamp(pitch + e.movementY * 0.004, 0.15, 1.1);
        }
    };
    const wheel = (e: WheelEvent) => {
        e.preventDefault();
        distance = T.MathUtils.clamp(distance + e.deltaY * 0.008, 4, 14);
    };
    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    window.addEventListener("blur", blur);
    renderer.domElement.addEventListener("pointerdown", pointerDown);
    renderer.domElement.addEventListener("pointerup", pointerUp);
    renderer.domElement.addEventListener("pointermove", pointerMove);
    renderer.domElement.addEventListener("wheel", wheel, { passive: false });
    const resize = () => {
        renderer.setSize(host.clientWidth, host.clientHeight);
        camera.aspect = host.clientWidth / host.clientHeight;
        camera.updateProjectionMatrix();
    };
    const observer = new ResizeObserver(resize);
    observer.observe(host);
    resize();
    camera.position.copy(position).add(new T.Vector3(0, 5, 8));
    function tick(now: number) {
        const dt = Math.min((now - last) / 1000, 0.04);
        last = now;
        time += dt;
        const f =
            Number(keys.has("KeyW") || keys.has("ArrowUp")) -
            Number(keys.has("KeyS") || keys.has("ArrowDown"));
        const s =
            Number(keys.has("KeyD") || keys.has("ArrowRight")) -
            Number(keys.has("KeyA") || keys.has("ArrowLeft"));
        const move = new T.Vector3(s, 0, -f)
            .normalize()
            .applyAxisAngle(T.Object3D.DEFAULT_UP, yaw);
        if (f || s) destination = null;
        if (destination) {
            move.copy(destination).sub(position);
            move.y = 0;
            if (move.length() < 0.15) destination = null;
            else move.normalize();
        }
        const speed = keys.has("ShiftLeft") || keys.has("ShiftRight") ? 7 : 4;
        const next = position.clone().addScaledVector(move, speed * dt);
        if (
            Math.hypot(next.x, next.z) < 24 &&
            !solids.some(
                (o) => Math.hypot(next.x - o.x, next.z - o.z) < o.r + 0.35,
            )
        ) {
            position.x = next.x;
            position.z = next.z;
        }
        const floor = ground(position.x, position.z);
        if (position.y <= floor + 0.015 && keys.has("Space")) {
            vy = 6;
            keys.delete("Space");
        }
        vy -= 16 * dt;
        position.y = Math.max(floor, position.y + vy * dt);
        if (position.y === floor) vy = 0;
        avatar.position.copy(position);
        if (move.lengthSq() > 0.01)
            avatar.rotation.y = Math.atan2(move.x, move.z);
        legs.forEach(
            (l, i) =>
                (l.rotation.x =
                    move.lengthSq() > 0.01
                        ? Math.sin(time * speed * 3 + i * Math.PI) * 0.55
                        : 0),
        );
        const target = position.clone().add(new T.Vector3(0, 1.1, 0));
        const offset = new T.Vector3(
            Math.sin(yaw) * Math.cos(pitch) * distance,
            Math.sin(pitch) * distance,
            Math.cos(yaw) * Math.cos(pitch) * distance,
        );
        const desired = target.clone().add(offset);
        desired.y = Math.max(desired.y, ground(desired.x, desired.z) + 0.7);
        camera.position.lerp(desired, 1 - Math.exp(-8 * dt));
        camera.lookAt(target);
        companion.position.lerp(
            position
                .clone()
                .add(new T.Vector3(1.2, 1.6 + Math.sin(time * 2) * 0.2, 1.2)),
            dt * 3,
        );
        companion.rotation.y = time;
        wolf.rotation.y = Math.sin(time * 0.6) * 0.2;
        leaves.forEach((l, i) => (l.rotation.z = Math.sin(time + i) * 0.025));
        const wa = waterGeo.attributes.position;
        for (let i = 0; i < wa.count; i++)
            wa.setY(
                i,
                Math.sin(wa.getX(i) * 0.16 + time) * 0.13 +
                    Math.cos(wa.getZ(i) * 0.19 + time * 0.7) * 0.1,
            );
        wa.needsUpdate = true;
        const n = Math.hypot(position.x - WOLF.x, position.z - WOLF.z) < 3;
        if (n !== near) {
            near = n;
            onNear(n);
        }
        renderer.render(scene, camera);
        frame = requestAnimationFrame(tick);
    }
    frame = requestAnimationFrame(tick);
    return () => {
        cancelAnimationFrame(frame);
        observer.disconnect();
        window.removeEventListener("keydown", down);
        window.removeEventListener("keyup", up);
        window.removeEventListener("blur", blur);
        renderer.domElement.removeEventListener("pointerdown", pointerDown);
        renderer.domElement.removeEventListener("pointerup", pointerUp);
        renderer.domElement.removeEventListener("pointermove", pointerMove);
        renderer.domElement.removeEventListener("wheel", wheel);
        scene.traverse((o) => {
            if (o instanceof T.Mesh) {
                o.geometry.dispose();
                const mats = Array.isArray(o.material)
                    ? o.material
                    : [o.material];
                mats.forEach((m) => m.dispose());
            }
        });
        renderer.dispose();
        renderer.domElement.remove();
    };
}
